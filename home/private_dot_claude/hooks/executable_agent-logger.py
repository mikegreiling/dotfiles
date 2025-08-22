#!/usr/bin/env python3
"""
Claude Code Agent Logging System

This script captures and logs agent/sub-agent interactions for debugging purposes.
It creates session-based logs with clear agent hierarchy and tool usage tracking.
"""

import json
import sys
import os
import fcntl
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

# Configuration
LOGS_DIR = Path.home() / ".claude" / "logs" / "sessions"
MAX_LOG_SIZE = 10 * 1024 * 1024  # 10MB per log file
TIMEZONE_OFFSET = time.strftime("%z")

class AgentLogger:
    def __init__(self, session_id: str, hook_type: str):
        self.session_id = session_id
        self.hook_type = hook_type
        self.timestamp = datetime.now()
        
        # Create session directory
        self.session_dir = LOGS_DIR / self.timestamp.strftime("%Y-%m-%d") / session_id
        self.session_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize metadata if it doesn't exist
        self.metadata_file = self.session_dir / "metadata.json"
        self._init_metadata()
    
    def _init_metadata(self):
        """Initialize session metadata file"""
        if not self.metadata_file.exists():
            metadata = {
                "session_id": self.session_id,
                "created_at": self.timestamp.isoformat(),
                "hooks_triggered": [],
                "agents_used": [],
                "tools_called": []
            }
            self._write_json(self.metadata_file, metadata)
    
    def _write_json(self, file_path: Path, data: Dict[str, Any]):
        """Thread-safe JSON writing with file locking"""
        with open(file_path, 'w') as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            json.dump(data, f, indent=2)
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    
    def _append_log(self, log_file: Path, entry: str):
        """Thread-safe log appending with file locking and rotation"""
        # Check file size and rotate if needed
        if log_file.exists() and log_file.stat().st_size > MAX_LOG_SIZE:
            archive_name = log_file.with_suffix(f".{int(time.time())}.log")
            log_file.rename(archive_name)
        
        with open(log_file, 'a', encoding='utf-8') as f:
            fcntl.flock(f.fileno(), fcntl.LOCK_EX)
            f.write(entry + '\n')
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)
    
    def _update_metadata(self, updates: Dict[str, Any]):
        """Update session metadata"""
        if self.metadata_file.exists():
            with open(self.metadata_file, 'r') as f:
                metadata = json.load(f)
        else:
            metadata = {}
        
        # Update metadata with new information
        for key, value in updates.items():
            if key in ["hooks_triggered", "agents_used", "tools_called"]:
                if key not in metadata:
                    metadata[key] = []
                if value not in metadata[key]:
                    metadata[key].append(value)
            else:
                metadata[key] = value
        
        self._write_json(self.metadata_file, metadata)
    
    def _format_log_entry(self, input_data: Dict[str, Any]) -> str:
        """Format a log entry with proper structure"""
        timestamp = self.timestamp.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3] + TIMEZONE_OFFSET
        
        # Build the log entry
        lines = [
            f"{'=' * 80}",
            f"TIMESTAMP: {timestamp}",
            f"HOOK_TYPE: {self.hook_type}",
            f"SESSION_ID: {self.session_id}",
        ]
        
        # Add context information
        if "cwd" in input_data:
            lines.append(f"WORKING_DIR: {input_data['cwd']}")
        
        # Tool-specific information
        if "tool_name" in input_data:
            tool_name = input_data["tool_name"]
            lines.append(f"TOOL: {tool_name}")
            
            # Handle Task tool (sub-agent invocation)
            if tool_name == "Task" and "tool_input" in input_data:
                tool_input = input_data["tool_input"]
                if isinstance(tool_input, dict):
                    lines.extend([
                        f"SUB_AGENT: {tool_input.get('subagent_type', 'unknown')}",
                        f"TASK_DESC: {tool_input.get('description', '')}",
                        "AGENT_PROMPT:",
                        "-" * 40,
                        tool_input.get('prompt', ''),
                        "-" * 40
                    ])
            
            # Handle other tool inputs
            elif "tool_input" in input_data:
                lines.extend([
                    "TOOL_INPUT:",
                    "-" * 40,
                    json.dumps(input_data["tool_input"], indent=2),
                    "-" * 40
                ])
        
        # Add tool output if available
        if "tool_output" in input_data:
            lines.extend([
                "TOOL_OUTPUT:",
                "-" * 40,
                str(input_data["tool_output"]),
                "-" * 40
            ])
        
        # Add any error information
        if "error" in input_data:
            lines.extend([
                "ERROR:",
                "-" * 40,
                str(input_data["error"]),
                "-" * 40
            ])
        
        # Add raw input data for debugging
        if os.environ.get("CLAUDE_DEBUG_VERBOSE"):
            lines.extend([
                "RAW_INPUT:",
                "-" * 40,
                json.dumps(input_data, indent=2),
                "-" * 40
            ])
        
        lines.append("")  # Empty line for readability
        return '\n'.join(lines)
    
    def log(self, input_data: Dict[str, Any]):
        """Main logging method"""
        try:
            # Determine the appropriate log file
            tool_name = input_data.get("tool_name", "main")
            
            if tool_name == "Task" and "tool_input" in input_data:
                tool_input = input_data["tool_input"]
                if isinstance(tool_input, dict):
                    agent_type = tool_input.get("subagent_type", "unknown")
                    log_file = self.session_dir / f"agent_{agent_type}.log"
                else:
                    log_file = self.session_dir / "main.log"
            else:
                log_file = self.session_dir / "main.log"
            
            # Format and write the log entry
            log_entry = self._format_log_entry(input_data)
            self._append_log(log_file, log_entry)
            
            # Update metadata
            metadata_updates = {
                "hooks_triggered": self.hook_type,
                "last_activity": self.timestamp.isoformat()
            }
            
            if "tool_name" in input_data:
                metadata_updates["tools_called"] = input_data["tool_name"]
            
            if tool_name == "Task" and "tool_input" in input_data:
                tool_input = input_data["tool_input"]
                if isinstance(tool_input, dict):
                    agent_type = tool_input.get("subagent_type", "unknown")
                    metadata_updates["agents_used"] = agent_type
            
            self._update_metadata(metadata_updates)
            
            # Success
            sys.exit(0)
            
        except Exception as e:
            # Log the error to stderr and a fallback file
            error_msg = f"Agent logger error in {self.hook_type}: {str(e)}"
            print(error_msg, file=sys.stderr)
            
            try:
                error_file = self.session_dir / "errors.log"
                self._append_log(error_file, f"{self.timestamp.isoformat()} - {error_msg}")
            except:
                pass  # If we can't log the error, don't fail completely
            
            sys.exit(0)  # Don't block Claude execution on logging errors

def main():
    """Main entry point for the logger"""
    try:
        # Read input from stdin
        input_data = json.load(sys.stdin)
        
        # Extract session information
        session_id = input_data.get("session_id", f"session_{int(time.time())}")
        hook_type = input_data.get("hook_event_name", "unknown")
        
        # Create logger and log the event
        logger = AgentLogger(session_id, hook_type)
        logger.log(input_data)
        
    except json.JSONDecodeError as e:
        print(f"Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(0)  # Don't block on JSON errors
    except Exception as e:
        print(f"Unexpected error in agent logger: {e}", file=sys.stderr)
        sys.exit(0)  # Don't block on unexpected errors

if __name__ == "__main__":
    main()