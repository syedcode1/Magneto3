# MAGNETO v3 - Architecture Diagrams

This document contains architectural diagrams for the MAGNETO v3 Attack Simulation Framework.

## 1. System Architecture Overview

```mermaid
graph TB
    subgraph "User Interface Layer"
        GUI[MAGNETO GUI v3<br/>Windows Forms Interface]
        CLI[Command Line Interface<br/>Direct PS1 Execution]
        BAT[Launch_MAGNETO_v3.bat<br/>Launcher]
    end
    
    subgraph "Core Engine Layer"
        CORE[MAGNETO_v3.ps1<br/>Core Attack Engine]
        CONFIG[Configuration Manager<br/>Parameters & Settings]
        VALIDATOR[Pre-Flight Validator<br/>Privilege & Compatibility Checks]
    end
    
    subgraph "Attack Framework"
        TECH[Technique Library<br/>55+ MITRE ATT&CK TTPs]
        APT[APT Campaign Definitions<br/>7 Threat Actor Profiles]
        INDUSTRY[Industry Verticals<br/>10 Sector Scenarios]
        NIST[NIST 800-53 Mappings<br/>Security Control Validation]
    end
    
    subgraph "Execution Layer"
        LOLBIN[Native Windows Binaries<br/>LOLBins Execution]
        REMOTE[Remote Execution<br/>PSRemoting Support]
        VALIDATE[Validation Engine<br/>Admin/Domain Checks]
    end
    
    subgraph "Logging & Reporting"
        LOGS[Attack Logs<br/>TXT Format]
        REPORTS[HTML Reports<br/>MITRE Heatmaps]
        SIEM[SIEM Events<br/>Windows Event Logs]
        CONSOLE[Console Output<br/>Real-time Status]
    end
    
    BAT --> GUI
    BAT --> CLI
    GUI --> CORE
    CLI --> CORE
    
    CORE --> CONFIG
    CORE --> VALIDATOR
    CONFIG --> TECH
    CONFIG --> APT
    CONFIG --> INDUSTRY
    CONFIG --> NIST
    
    TECH --> VALIDATE
    APT --> VALIDATE
    INDUSTRY --> VALIDATE
    
    VALIDATE --> LOLBIN
    VALIDATE --> REMOTE
    
    LOLBIN --> LOGS
    LOLBIN --> REPORTS
    LOLBIN --> SIEM
    LOLBIN --> CONSOLE
    
    style GUI fill:#2d5016,stroke:#00ff00,stroke-width:3px,color:#fff
    style CLI fill:#2d5016,stroke:#00ff00,stroke-width:3px,color:#fff
    style CORE fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
    style LOLBIN fill:#0a2d5c,stroke:#00ccff,stroke-width:3px,color:#fff
    style REPORTS fill:#5c4d0a,stroke:#ffcc00,stroke-width:2px,color:#fff
```

## 2. Attack Execution Flow

```mermaid
flowchart TD
    START([User Initiates Attack]) --> INPUT{Input Method?}
    
    INPUT -->|GUI| GUI[Load GUI Interface<br/>MAGNETO_GUI_v3.ps1]
    INPUT -->|CLI| CLI[Direct Execution<br/>MAGNETO_v3.ps1]
    
    GUI --> SELECT[User Selects Configuration:<br/>- APT Campaign or Random<br/>- Industry Vertical optional<br/>- Tactic/Technique Filters<br/>- Execution Parameters]
    CLI --> PARAM[Parse CLI Parameters:<br/>APTCampaign<br/>AttackMode<br/>Filters & Options]
    
    SELECT --> CONFIG[Build Attack Configuration]
    PARAM --> CONFIG
    
    CONFIG --> LOAD[Load Technique Definitions<br/>55+ MITRE ATT&CK TTPs]
    
    LOAD --> FILTER{Apply Filters?}
    
    FILTER -->|APT Campaign| APT[Load APT-Specific<br/>Technique Chain]
    FILTER -->|Industry Vertical| INDUSTRY[Load Industry-Specific<br/>Threat Scenarios]
    FILTER -->|Tactic Filter| TACTIC[Filter by MITRE Tactics]
    FILTER -->|Technique Filter| TECHFILTER[Include/Exclude Techniques]
    FILTER -->|Random Mode| RANDOM[Select Random Techniques<br/>with Daily Variance]
    
    APT --> SELECTED[Selected Techniques Array]
    INDUSTRY --> SELECTED
    TACTIC --> SELECTED
    TECHFILTER --> SELECTED
    RANDOM --> SELECTED
    
    SELECTED --> LOOP[For Each Technique]
    
    LOOP --> VALID{Validation<br/>Required?}
    
    VALID -->|Yes| CHECK{Pass<br/>Validation?}
    VALID -->|No| EXEC
    
    CHECK -->|Admin Required| ADMIN{Has Admin<br/>Privileges?}
    CHECK -->|Domain Required| DOMAIN{Domain<br/>Joined?}
    CHECK -->|Custom Check| CUSTOM{Custom<br/>Validation}
    
    ADMIN -->|No| SKIP[SKIP - Log Reason]
    ADMIN -->|Yes| EXEC[Execute Technique Action]
    DOMAIN -->|No| SKIP
    DOMAIN -->|Yes| EXEC
    CUSTOM -->|Fail| SKIP
    CUSTOM -->|Pass| EXEC
    
    EXEC --> RUN{WhatIf<br/>Mode?}
    
    RUN -->|Yes| SIMULATE[Display What Would Execute]
    RUN -->|No| EXECUTE[Execute LOLBin Command<br/>Native Windows Binary]
    
    SIMULATE --> RESULT
    EXECUTE --> RESULT[Record Result:<br/>Success/Fail/Skipped]
    
    SKIP --> RESULT
    
    RESULT --> LOG[Log to Attack Log<br/>Console Output<br/>Windows Events]
    
    LOG --> NEXT{More<br/>Techniques?}
    
    NEXT -->|Yes| DELAY[Delay Between Techniques<br/>Default: 2 seconds]
    NEXT -->|No| CLEANUP{Cleanup<br/>Enabled?}
    
    DELAY --> LOOP
    
    CLEANUP -->|Yes| CLEAN[Execute Cleanup Actions<br/>Remove Artifacts]
    CLEANUP -->|No| SUMMARY
    
    CLEAN --> SUMMARY[Generate Execution Summary:<br/>- Total Attempted<br/>- Successful<br/>- Skipped<br/>- Failed]
    
    SUMMARY --> REPORT[Generate Reports:<br/>- TXT Attack Log<br/>- HTML Report optional<br/>- MITRE Heatmap<br/>- NIST Mappings]
    
    REPORT --> END([Simulation Complete])
    
    style START fill:#2d5016,stroke:#00ff00,stroke-width:3px,color:#fff
    style END fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
    style EXECUTE fill:#0a2d5c,stroke:#00ccff,stroke-width:3px,color:#fff
    style SKIP fill:#5c4d0a,stroke:#ffcc00,stroke-width:2px,color:#fff
    style REPORT fill:#4d0a5c,stroke:#ff00ff,stroke-width:2px,color:#fff
```

## 3. GUI to Core Interaction

```mermaid
sequenceDiagram
    participant User
    participant GUI as MAGNETO GUI
    participant Launcher as Launch Script
    participant Core as MAGNETO Core
    participant LOLBin as Windows Binaries
    participant Log as Logging System
    participant Report as Report Generator
    
    User->>Launcher: Double-click Launch_MAGNETO_v3.bat
    activate Launcher
    Launcher->>Launcher: Check Admin Privileges
    Launcher->>Launcher: Verify PowerShell Version
    Launcher->>Launcher: Validate Required Files
    Launcher->>Launcher: Create Folder Structure
    Launcher->>GUI: Launch MAGNETO_GUI_v3.ps1
    deactivate Launcher
    
    activate GUI
    GUI->>GUI: Load Techniques from Core Script
    GUI->>GUI: Load APT Campaign Definitions
    GUI->>GUI: Initialize UI Components
    GUI->>User: Display Splash Screen (4s)
    GUI->>User: Show Main Interface
    deactivate GUI
    
    User->>GUI: Select APT Campaign / Configure Attack
    activate GUI
    GUI->>GUI: Update Technique List
    GUI->>GUI: Show APT Intelligence
    deactivate GUI
    
    User->>GUI: Click "EXECUTE ATTACK"
    activate GUI
    GUI->>GUI: Build PowerShell Command
    GUI->>GUI: Start Background Job
    GUI->>Core: Execute MAGNETO_v3.ps1 with Parameters
    deactivate GUI
    
    activate Core
    Core->>Core: Parse Parameters
    Core->>Core: Load Technique Definitions
    Core->>Core: Apply Filters (APT/Tactic/Technique)
    Core->>Core: Select Techniques to Execute
    
    loop For Each Technique
        Core->>Core: Validate Prerequisites
        alt Validation Passed
            Core->>LOLBin: Execute Native Windows Binary
            activate LOLBin
            LOLBin-->>Core: Return Result
            deactivate LOLBin
            Core->>Log: Write Attack Log Entry
            Core->>Log: Generate Windows Event
            Core->>GUI: Update Console Output
            GUI->>User: Display Real-time Status
            GUI->>GUI: Flash Red Alert
        else Validation Failed
            Core->>Log: Log Skipped Technique
            Core->>GUI: Update with Skip Reason
        end
        Core->>Core: Delay Between Techniques
    end
    
    Core->>Core: Generate Execution Summary
    Core->>Report: Create Attack Log (TXT)
    activate Report
    Report->>Report: Write Technique Details
    Report->>Report: Add MITRE Mappings
    Report->>Report: Include Command Log
    Report-->>Core: Log File Path
    deactivate Report
    
    Core->>GUI: Signal Completion
    deactivate Core
    
    activate GUI
    GUI->>GUI: Stop Flash Alert
    GUI->>GUI: Update Final Status
    GUI->>User: Display Results Summary
    GUI->>User: Show Log File Link
    deactivate GUI
    
    User->>GUI: Click "View Log"
    activate GUI
    GUI->>User: Open Attack Log in Notepad
    deactivate GUI
```

## 4. MITRE ATT&CK Tactic Coverage

```mermaid
graph LR
    subgraph "MITRE ATT&CK Tactics"
        RECON[Reconnaissance<br/>2 Techniques]
        IA[Initial Access<br/>3 Techniques]
        EXEC[Execution<br/>6 Techniques]
        PERSIST[Persistence<br/>8 Techniques]
        PRIVESC[Privilege Escalation<br/>5 Techniques]
        EVASION[Defense Evasion<br/>10 Techniques]
        CREDACCESS[Credential Access<br/>7 Techniques]
        DISCOVERY[Discovery<br/>9 Techniques]
        LATERAL[Lateral Movement<br/>3 Techniques]
        COLLECTION[Collection<br/>4 Techniques]
        EXFIL[Exfiltration<br/>3 Techniques]
        C2[Command & Control<br/>2 Techniques]
        IMPACT[Impact<br/>3 Techniques]
    end
    
    subgraph "Attack Kill Chain"
        direction TB
        RECON -.-> IA
        IA -.-> EXEC
        EXEC -.-> PERSIST
        PERSIST -.-> PRIVESC
        PRIVESC -.-> EVASION
        EVASION -.-> CREDACCESS
        CREDACCESS -.-> DISCOVERY
        DISCOVERY -.-> LATERAL
        LATERAL -.-> COLLECTION
        COLLECTION -.-> EXFIL
        C2 -.-> EXFIL
        COLLECTION -.-> IMPACT
    end
    
    style RECON fill:#1a472a,stroke:#2ecc71,stroke-width:2px,color:#fff
    style IA fill:#5c3317,stroke:#e67e22,stroke-width:2px,color:#fff
    style EXEC fill:#4a148c,stroke:#9b59b6,stroke-width:2px,color:#fff
    style PERSIST fill:#0d47a1,stroke:#3498db,stroke-width:2px,color:#fff
    style PRIVESC fill:#b71c1c,stroke:#e74c3c,stroke-width:2px,color:#fff
    style EVASION fill:#f57c00,stroke:#f39c12,stroke-width:2px,color:#fff
    style CREDACCESS fill:#880e4f,stroke:#e91e63,stroke-width:2px,color:#fff
    style DISCOVERY fill:#1b5e20,stroke:#4caf50,stroke-width:2px,color:#fff
    style LATERAL fill:#006064,stroke:#00bcd4,stroke-width:2px,color:#fff
    style COLLECTION fill:#4a148c,stroke:#673ab7,stroke-width:2px,color:#fff
    style EXFIL fill:#bf360c,stroke:#ff5722,stroke-width:2px,color:#fff
    style C2 fill:#263238,stroke:#607d8b,stroke-width:2px,color:#fff
    style IMPACT fill:#b71c1c,stroke:#f44336,stroke-width:3px,color:#fff
```

## 5. APT Campaign Attack Chains

```mermaid
graph TD
    subgraph "APT41 - Shadow Harvest"
        A1[T1049<br/>Network Discovery] --> A2[T1087.001<br/>Domain Account Enum]
        A2 --> A3[T1218.011<br/>Rundll32 Proxy]
        A3 --> A4[T1546.015<br/>COM Hijacking]
        A4 --> A5[T1055.100<br/>Process Injection]
        A5 --> A6[T1550.002<br/>Pass-the-Hash]
        A6 --> A7[T1021.002<br/>SMB Lateral Movement]
        A7 --> A8[T1041<br/>Web Service Exfil]
    end
    
    subgraph "Lazarus - DEV#POPPER"
        L1[T1574.002<br/>DLL Side-Loading] --> L2[T1053.005<br/>Scheduled Task]
        L2 --> L3[T1003.003<br/>NTDS Dumping]
        L3 --> L4[T1021.002<br/>SMB Movement]
        L4 --> L5[T1560.002<br/>Archive Collection]
    end
    
    subgraph "APT29 - GRAPELOADER"
        P1[T1546.015<br/>COM Hijacking] --> P2[T1053.005<br/>Scheduled Task]
        P2 --> P3[T1134.001<br/>Token Manipulation]
        P3 --> P4[T1070.004<br/>File Deletion]
    end
    
    subgraph "FIN7 - Carbanak"
        F1[T1059.001<br/>PowerShell] --> F2[T1105<br/>File Download]
        F2 --> F3[T1543.003<br/>Service Persistence]
    end
    
    style A8 fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
    style L5 fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
    style P4 fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
    style F3 fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
```

## 6. Technique Execution Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Queued: Technique Selected
    
    Queued --> Validating: Start Execution
    
    Validating --> CheckAdmin: Requires Admin?
    Validating --> CheckDomain: Requires Domain?
    Validating --> CheckCustom: Custom Validation?
    Validating --> ReadyToExecute: No Validation
    
    CheckAdmin --> SkippedAdmin: No Admin Privileges
    CheckAdmin --> ReadyToExecute: Has Admin
    
    CheckDomain --> SkippedDomain: Not Domain Joined
    CheckDomain --> ReadyToExecute: Domain Joined
    
    CheckCustom --> SkippedCustom: Validation Failed
    CheckCustom --> ReadyToExecute: Validation Passed
    
    ReadyToExecute --> WhatIfMode: WhatIf Enabled?
    ReadyToExecute --> Executing: Normal Mode
    
    WhatIfMode --> Simulated: Display Intent
    
    Executing --> Success: Execution Successful
    Executing --> Failed: Execution Failed
    
    Success --> Logging: Record Result
    Failed --> Logging: Record Result
    Simulated --> Logging: Record Simulation
    SkippedAdmin --> Logging: Record Skip
    SkippedDomain --> Logging: Record Skip
    SkippedCustom --> Logging: Record Skip
    
    Logging --> CleanupCheck: Cleanup Enabled?
    
    CleanupCheck --> Cleanup: Yes, Technique Successful
    CleanupCheck --> Complete: No Cleanup Needed
    
    Cleanup --> Complete: Artifacts Removed
    
    Complete --> [*]: Technique Finished
    
    note right of Validating
        Pre-flight checks ensure
        technique can execute
        in current environment
    end note
    
    note right of Executing
        Uses native Windows
        binaries (LOLBins)
        No malware or exploits
    end note
    
    note right of Cleanup
        Optional artifact removal
        Leaves no trace
    end note
```

## 7. Data Flow Architecture

```mermaid
graph TB
    subgraph "Input Sources"
        USER[User Input]
        CONFIG[Configuration Files]
        PARAMS[CLI Parameters]
    end
    
    subgraph "Processing"
        PARSER[Parameter Parser]
        SELECTOR[Technique Selector]
        FILTER[Filter Engine]
        VALIDATOR[Validation Engine]
    end
    
    subgraph "Execution"
        EXECUTOR[Execution Engine]
        LOLBIN[LOLBin Invocation]
        RESULT[Result Collector]
    end
    
    subgraph "Output Destinations"
        CONSOLE[Console Output]
        TXTLOG[Text Logs]
        HTMLREPORT[HTML Reports]
        EVENTLOG[Windows Event Logs]
        SIEM[SIEM Systems]
    end
    
    USER --> PARSER
    CONFIG --> PARSER
    PARAMS --> PARSER
    
    PARSER --> SELECTOR
    SELECTOR --> FILTER
    FILTER --> VALIDATOR
    
    VALIDATOR --> EXECUTOR
    EXECUTOR --> LOLBIN
    LOLBIN --> RESULT
    
    RESULT --> CONSOLE
    RESULT --> TXTLOG
    RESULT --> HTMLREPORT
    RESULT --> EVENTLOG
    EVENTLOG --> SIEM
    
    style USER fill:#2d5016,stroke:#00ff00,stroke-width:2px,color:#fff
    style LOLBIN fill:#0a2d5c,stroke:#00ccff,stroke-width:3px,color:#fff
    style SIEM fill:#5c0a0a,stroke:#ff0000,stroke-width:2px,color:#fff
```

## 8. Industry Vertical Threat Mapping

```mermaid
mindmap
    root((MAGNETO v3<br/>Industry Threats))
        Financial Services
            Lazarus
            FIN7
            APT38
            Wire Fraud
            Cryptocurrency Theft
            Ransomware
        Healthcare
            APT41
            LockBit
            ALPHV
            Patient Data Theft
            Ransomware
            Service Disruption
        Energy & Utilities
            APT33
            APT28
            Dragonfly
            ICS Compromise
            Infrastructure Damage
        Manufacturing
            APT41
            Supply Chain
            IP Theft
            Production Disruption
        Technology
            APT29
            Supply Chain
            Source Code Theft
            Cloud Attacks
        Government
            APT29
            APT28
            Lazarus
            Espionage
            Data Theft
        Education
            APT41
            Research IP Theft
            Ransomware
        Retail
            FIN7
            POS Malware
            Payment Data
```

## 9. Logging and Monitoring Architecture

```mermaid
graph LR
    subgraph "Attack Execution"
        TECH[Technique Execution] --> EVENTS[Generate Events]
    end
    
    subgraph "Local Logging"
        EVENTS --> TXTLOG[Attack Log TXT]
        EVENTS --> HTMLRPT[HTML Report]
        EVENTS --> WINLOG[Windows Event Log]
    end
    
    subgraph "Windows Event Logs"
        WINLOG --> SEC[Security Log<br/>4688,4624,4672]
        WINLOG --> SYS[System Log<br/>7045,7040]
        WINLOG --> APP[Application Log]
    end
    
    subgraph "SIEM Integration"
        SEC --> FORWARD[Event Forwarding]
        SYS --> FORWARD
        APP --> FORWARD
        
        FORWARD --> EXABEAM[Exabeam UEBA]
        FORWARD --> SPLUNK[Splunk ES]
        FORWARD --> QRADAR[IBM QRadar]
        FORWARD --> SENTINEL[MS Sentinel]
        FORWARD --> ELASTIC[Elastic SIEM]
    end
    
    subgraph "Analysis & Detection"
        EXABEAM --> DETECTION[Anomaly Detection]
        SPLUNK --> DETECTION
        QRADAR --> DETECTION
        SENTINEL --> DETECTION
        ELASTIC --> DETECTION
        
        DETECTION --> ALERT[Security Alerts]
        DETECTION --> DASHBOARD[SOC Dashboard]
        DETECTION --> INCIDENT[Incident Response]
    end
    
    style TECH fill:#2d5016,stroke:#00ff00,stroke-width:2px,color:#fff
    style WINLOG fill:#0a2d5c,stroke:#00ccff,stroke-width:2px,color:#fff
    style DETECTION fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
    style ALERT fill:#5c0a0a,stroke:#ff0000,stroke-width:3px,color:#fff
```

---

## Diagram Usage Notes

### Viewing Diagrams
- These Mermaid diagrams render automatically on GitHub
- For local viewing, use:
  - VS Code with Mermaid extension
  - Online viewer: https://mermaid.live
  - Markdown preview tools with Mermaid support

### Color Coding Legend
- 🟢 **Green**: User interfaces, input sources, successful operations
- 🔴 **Red**: Critical operations, attack execution, alerts
- 🔵 **Blue**: Core processing, execution engines
- 🟡 **Yellow**: Warnings, skipped operations
- 🟣 **Purple**: Reporting, output generation

### Diagram Categories
1. **Architecture** - System component relationships
2. **Flow** - Process execution sequences
3. **Sequence** - Component interactions over time
4. **State** - Technique lifecycle states
5. **Mind Map** - Threat landscape overview

---

*For implementation details, refer to the source code and README.md*
