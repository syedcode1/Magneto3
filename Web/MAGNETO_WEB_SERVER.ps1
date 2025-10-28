# MAGNETO WEB SERVER v3 - Pure PowerShell Web Interface
# Version 3.0 - Modern Hacker Edition
# 100% PowerShell - No external dependencies

param(
    [int]$Port = 8080,
    [string]$BindAddress = "http://localhost"
)

try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force -ErrorAction SilentlyContinue
} catch {}

$script:currentVersion = "3.3.1"
$script:magnetoScriptPath = Join-Path $PSScriptRoot "MAGNETO_v3.ps1"
$script:isRunning = $false
$script:currentJob = $null
$script:executedTechniques = @()
$script:techniques = @()

function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $Color
}

function Load-Techniques {
    Write-ColorOutput "[>] Loading techniques from MAGNETO v3 script..." -Color Cyan
    if (-not (Test-Path $script:magnetoScriptPath)) {
        Write-ColorOutput "[!] MAGNETO_v3.ps1 not found at: $script:magnetoScriptPath" -Color Red
        return @()
    }
    try {
        $scriptContent = Get-Content $script:magnetoScriptPath -Raw

        # Pattern to match technique blocks in array format
        $pattern = '@\{\s*ID\s*=\s*[''"]([^''"]+)[''"]\s*Name\s*=\s*[''"]([^''"]+)[''"]\s*Tactic\s*=\s*[''"]([^''"]+)[''"]'
        $matches = [regex]::Matches($scriptContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $loadedTechniques = @()
        foreach ($match in $matches) {
            $techId = $match.Groups[1].Value.Trim()
            $techName = $match.Groups[2].Value.Trim()
            $techTactic = $match.Groups[3].Value.Trim()

            $loadedTechniques += @{
                ID = $techId
                Name = $techName
                Tactic = $techTactic
                Description = "$techName - $techTactic"
            }
        }

        Write-ColorOutput "[+] Loaded $($loadedTechniques.Count) techniques successfully" -Color Green
        return $loadedTechniques
    }
    catch {
        Write-ColorOutput "[!] Error loading techniques: $($_.Exception.Message)" -Color Red
        return @()
    }
}

function Get-HTMLContent {
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MAGNETO v3 - Advanced APT Simulator</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-primary: #0f0f0f;
            --bg-secondary: #1a1a1a;
            --bg-tertiary: #222;
            --accent-primary: #00ff88;
            --accent-secondary: #ff0066;
            --accent-blue: #0099ff;
            --text-primary: #e0e0e0;
            --text-secondary: #999;
            --border: #333;
            --shadow: rgba(0, 255, 136, 0.1);
        }
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            line-height: 1.6;
            overflow-x: hidden;
        }
        .container {
            max-width: 1800px;
            margin: 0 auto;
            padding: 24px;
        }
        .header {
            background: linear-gradient(135deg, var(--bg-secondary) 0%, #1a1a2e 100%);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 32px;
            margin-bottom: 24px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
            position: relative;
            overflow: hidden;
        }
        .header::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, var(--accent-primary), transparent);
        }
        .title-container {
            display: flex;
            align-items: center;
            gap: 16px;
            margin-bottom: 12px;
        }
        .logo {
            width: 56px;
            height: 56px;
            background: linear-gradient(135deg, var(--accent-primary), var(--accent-blue));
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 28px;
            font-weight: bold;
            color: var(--bg-primary);
        }
        .title {
            font-size: 2.5em;
            font-weight: 700;
            background: linear-gradient(135deg, var(--accent-primary), var(--accent-blue));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .subtitle {
            font-size: 1em;
            color: var(--text-secondary);
            font-weight: 400;
        }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            background: rgba(0, 255, 136, 0.1);
            border: 1px solid var(--accent-primary);
            border-radius: 12px;
            font-size: 0.75em;
            font-weight: 600;
            color: var(--accent-primary);
            margin-left: 8px;
        }
        .control-panel {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 24px;
            margin-bottom: 24px;
        }
        .section-title {
            font-size: 0.875em;
            font-weight: 600;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .section-title::before {
            content: '';
            width: 3px;
            height: 14px;
            background: var(--accent-primary);
            border-radius: 2px;
        }
        .control-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 16px;
            margin-bottom: 20px;
        }
        .control-group {
            display: flex;
            flex-direction: column;
            gap: 8px;
        }
        label {
            font-size: 0.875em;
            font-weight: 500;
            color: var(--text-secondary);
        }
        select, input[type="number"] {
            background: var(--bg-tertiary);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px 16px;
            color: var(--text-primary);
            font-size: 0.9375em;
            font-family: inherit;
            transition: all 0.2s ease;
        }
        select:hover, input[type="number"]:hover {
            border-color: var(--accent-primary);
        }
        select:focus, input[type="number"]:focus {
            outline: none;
            border-color: var(--accent-primary);
            box-shadow: 0 0 0 3px rgba(0, 255, 136, 0.1);
        }
        .apt-info {
            background: linear-gradient(135deg, rgba(255, 0, 102, 0.05), rgba(255, 0, 102, 0.02));
            border: 1px solid rgba(255, 0, 102, 0.2);
            border-radius: 12px;
            padding: 16px;
            margin-top: 16px;
            display: none;
        }
        .apt-info.active {
            display: block;
            animation: slideIn 0.3s ease;
        }
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-8px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        .apt-title {
            font-size: 1em;
            font-weight: 600;
            color: var(--accent-secondary);
            margin-bottom: 8px;
        }
        .apt-description {
            font-size: 0.875em;
            color: var(--text-secondary);
            line-height: 1.5;
        }
        .btn-group {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }
        .btn {
            flex: 1;
            min-width: 140px;
            padding: 14px 24px;
            font-family: inherit;
            font-size: 0.9375em;
            font-weight: 600;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
        }
        .btn-primary {
            background: linear-gradient(135deg, var(--accent-primary), #00cc70);
            color: var(--bg-primary);
        }
        .btn-primary:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(0, 255, 136, 0.3);
        }
        .btn-secondary {
            background: var(--bg-tertiary);
            color: var(--text-primary);
            border: 1px solid var(--border);
        }
        .btn-secondary:hover:not(:disabled) {
            background: var(--border);
            border-color: var(--accent-primary);
        }
        .btn-danger {
            background: linear-gradient(135deg, var(--accent-secondary), #cc0050);
            color: white;
        }
        .btn-danger:hover:not(:disabled) {
            transform: translateY(-2px);
            box-shadow: 0 8px 24px rgba(255, 0, 102, 0.3);
        }
        .btn:disabled {
            opacity: 0.4;
            cursor: not-allowed;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        .stat-card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 20px;
            position: relative;
            overflow: hidden;
        }
        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: var(--accent-primary);
        }
        .stat-label {
            font-size: 0.75em;
            font-weight: 600;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 8px;
        }
        .stat-value {
            font-size: 2.25em;
            font-weight: 700;
            color: var(--accent-primary);
            font-family: 'JetBrains Mono', monospace;
        }
        .stat-card.status .stat-value {
            font-size: 1.5em;
        }
        .main-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
        }
        @media (max-width: 1200px) {
            .main-grid {
                grid-template-columns: 1fr;
            }
        }
        .panel {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 16px;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            height: 600px;
        }
        .panel-header {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border);
            background: var(--bg-tertiary);
        }
        .panel-title {
            font-size: 0.9375em;
            font-weight: 600;
            color: var(--text-primary);
        }
        .panel-content {
            flex: 1;
            overflow-y: auto;
            padding: 16px;
        }
        .panel-content::-webkit-scrollbar {
            width: 8px;
        }
        .panel-content::-webkit-scrollbar-track {
            background: var(--bg-tertiary);
        }
        .panel-content::-webkit-scrollbar-thumb {
            background: var(--border);
            border-radius: 4px;
        }
        .panel-content::-webkit-scrollbar-thumb:hover {
            background: var(--accent-primary);
        }
        .technique-item {
            background: var(--bg-tertiary);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 12px 16px;
            margin-bottom: 8px;
            cursor: pointer;
            transition: all 0.2s ease;
        }
        .technique-item:hover {
            border-color: var(--accent-primary);
            background: rgba(0, 255, 136, 0.05);
        }
        .technique-item.selected {
            border-color: var(--accent-primary);
            background: rgba(0, 255, 136, 0.1);
            box-shadow: 0 0 0 1px var(--accent-primary);
        }
        .technique-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 6px;
        }
        .technique-id {
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.875em;
            font-weight: 600;
            color: var(--accent-secondary);
            background: rgba(255, 0, 102, 0.1);
            padding: 2px 8px;
            border-radius: 4px;
        }
        .technique-name {
            font-size: 0.9375em;
            font-weight: 500;
            color: var(--text-primary);
        }
        .technique-tactic {
            font-size: 0.8125em;
            color: var(--text-secondary);
        }
        .terminal {
            background: #000;
            font-family: 'JetBrains Mono', monospace;
            font-size: 0.8125em;
            line-height: 1.6;
        }
        .terminal-line {
            padding: 2px 0;
            word-wrap: break-word;
        }
        .log-success {
            color: var(--accent-primary);
        }
        .log-error {
            color: var(--accent-secondary);
        }
        .log-warning {
            color: #ffaa00;
        }
        .log-info {
            color: #888;
        }
        .log-command {
            color: var(--accent-blue);
        }
        .empty-state {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100%;
            color: var(--text-secondary);
            text-align: center;
            padding: 40px;
        }
        .empty-state-icon {
            font-size: 3em;
            margin-bottom: 16px;
            opacity: 0.5;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="title-container">
                <div class="logo">M</div>
                <div>
                    <h1 class="title">MAGNETO v3<span class="badge">WEB</span></h1>
                    <p class="subtitle">Advanced APT Campaign Simulator • 100% PowerShell • LOLBin Framework</p>
                </div>
            </div>
        </div>

        <div class="control-panel">
            <div class="section-title">Attack Configuration</div>
            <div class="control-grid">
                <div class="control-group">
                    <label>APT Campaign</label>
                    <select id="aptCampaign">
                        <option value="None">Standard Mode (Manual Selection)</option>
                        <option value="APT41">APT41 - Shadow Harvest</option>
                        <option value="Lazarus">Lazarus - DEV#POPPER</option>
                        <option value="APT29">APT29 - GRAPELOADER</option>
                        <option value="StealthFalcon">StealthFalcon - Project Raven</option>
                        <option value="FIN7">FIN7 - Carbanak</option>
                        <option value="APT28">APT28 - Fancy Bear</option>
                    </select>
                </div>
                <div class="control-group">
                    <label>Industry Vertical</label>
                    <select id="industryVertical">
                        <option value="">None (Use APT/Manual)</option>
                        <option value="Financial Services">Financial Services</option>
                        <option value="Healthcare">Healthcare</option>
                        <option value="Energy & Utilities">Energy & Utilities</option>
                        <option value="Manufacturing & OT">Manufacturing & OT</option>
                        <option value="Technology">Technology</option>
                        <option value="Government">Government</option>
                        <option value="Education & Research">Education & Research</option>
                        <option value="Retail & Hospitality">Retail & Hospitality</option>
                        <option value="Telecommunications">Telecommunications</option>
                        <option value="Transportation">Transportation</option>
                    </select>
                </div>
                <div class="control-group">
                    <label>Attack Mode</label>
                    <select id="attackMode">
                        <option value="Selected">Execute Selected Techniques</option>
                        <option value="Random">Random Technique Selection</option>
                    </select>
                </div>
                <div class="control-group">
                    <label>Technique Count (Random Mode)</label>
                    <input type="number" id="techniqueCount" min="1" max="38" value="5">
                </div>
            </div>
            <div id="aptInfo" class="apt-info"></div>
            <div class="btn-group">
                <button class="btn btn-primary" id="btnExecute">▶ Execute Attack</button>
                <button class="btn btn-danger" id="btnStop" disabled>⏹ Stop Execution</button>
                <button class="btn btn-secondary" id="btnReport">📊 Generate Report</button>
            </div>
        </div>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Total Techniques</div>
                <div class="stat-value" id="statTotal">0</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Selected</div>
                <div class="stat-value" id="statSelected">0</div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Executed</div>
                <div class="stat-value" id="statExecuted">0</div>
            </div>
            <div class="stat-card status">
                <div class="stat-label">Status</div>
                <div class="stat-value" id="statStatus">READY</div>
            </div>
        </div>

        <div class="main-grid">
            <div class="panel">
                <div class="panel-header">
                    <div class="panel-title">Available Techniques</div>
                </div>
                <div class="panel-content" id="techniqueList">
                    <div class="empty-state">
                        <div class="empty-state-icon">⚡</div>
                        <div>Loading techniques...</div>
                    </div>
                </div>
            </div>
            <div class="panel">
                <div class="panel-header">
                    <div class="panel-title">Execution Output</div>
                </div>
                <div class="panel-content terminal" id="terminalOutput">
                    <div class="terminal-line log-success">[MAGNETO WEB] System initialized</div>
                    <div class="terminal-line log-info">[SYSTEM] Awaiting commands...</div>
                </div>
            </div>
        </div>
    </div>

    <script>
        let techniques = [];
        let selectedTechniques = new Set();
        let isRunning = false;

        const aptCampaigns = {
            "APT41": {
                name: "Shadow Harvest",
                description: "Chinese espionage group targeting technology companies with Google Calendar C2 communication. Techniques: T1049, T1087.001, T1218.011, T1546.015, T1055.100, T1550.002, T1021.002, T1041",
                techniques: ["T1049", "T1087.001", "T1218.011", "T1546.015", "T1055.100", "T1550.002", "T1021.002", "T1041"]
            },
            "Lazarus": {
                name: "DEV#POPPER",
                description: "North Korean state-sponsored group conducting financial theft and cryptocurrency heists. Techniques: T1574.002, T1053.005, T1003.003, T1021.002, T1560.002",
                techniques: ["T1574.002", "T1053.005", "T1003.003", "T1021.002", "T1560.002"]
            },
            "APT29": {
                name: "GRAPELOADER",
                description: "Russian diplomatic espionage using sophisticated malware. Techniques: T1566.001, T1059.003, T1547.001, T1003.001",
                techniques: ["T1566.001", "T1059.003", "T1547.001", "T1003.001"]
            },
            "StealthFalcon": {
                name: "Project Raven",
                description: "Middle East targeting dissidents and journalists. Techniques: T1566.001, T1059.001, T1055.012",
                techniques: ["T1566.001", "T1059.001", "T1055.012"]
            },
            "FIN7": {
                name: "Carbanak",
                description: "Financial crime syndicate targeting payment systems. Techniques: T1566.001, T1059.003, T1056.001",
                techniques: ["T1566.001", "T1059.003", "T1056.001"]
            },
            "APT28": {
                name: "Fancy Bear",
                description: "Russian military intelligence cyber operations. Techniques: T1566.001, T1059.001, T1003.001",
                techniques: ["T1566.001", "T1059.001", "T1003.001"]
            }
        };

        document.addEventListener('DOMContentLoaded', () => {
            loadTechniques();
            setupEventListeners();
            startStatusPolling();
        });

        function setupEventListeners() {
            document.getElementById('aptCampaign').addEventListener('change', handleAPTChange);
            document.getElementById('btnExecute').addEventListener('click', executeAttack);
            document.getElementById('btnStop').addEventListener('click', stopExecution);
            document.getElementById('btnReport').addEventListener('click', generateReport);
        }

        function handleAPTChange(e) {
            const aptValue = e.target.value;
            const aptInfo = document.getElementById('aptInfo');
            if (aptValue !== 'None' && aptCampaigns[aptValue]) {
                const apt = aptCampaigns[aptValue];
                aptInfo.innerHTML = '<div class="apt-title">🎯 ' + apt.name + '</div><div class="apt-description">' + apt.description + '</div>';
                aptInfo.classList.add('active');
                selectedTechniques.clear();
                apt.techniques.forEach(tid => selectedTechniques.add(tid));
                updateTechniqueDisplay();
            } else {
                aptInfo.classList.remove('active');
            }
        }

        async function loadTechniques() {
            try {
                const response = await fetch('/api/techniques');
                const data = await response.json();
                techniques = data.techniques || [];
                document.getElementById('statTotal').textContent = techniques.length;
                displayTechniques();
                logToTerminal('success', '[SYSTEM] Loaded ' + techniques.length + ' techniques from MAGNETO v3');
            } catch (error) {
                logToTerminal('error', '[ERROR] Failed to load techniques: ' + error.message);
            }
        }

        function displayTechniques() {
            const container = document.getElementById('techniqueList');
            if (techniques.length === 0) {
                container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div>No techniques found. Check MAGNETO_v3.ps1 file.</div></div>';
                return;
            }
            container.innerHTML = '';
            techniques.forEach(tech => {
                const div = document.createElement('div');
                div.className = 'technique-item';
                div.innerHTML = '<div class="technique-header"><span class="technique-id">' + tech.ID + '</span><span class="technique-name">' + tech.Name + '</span></div><div class="technique-tactic">Tactic: ' + tech.Tactic + '</div>';
                div.addEventListener('click', () => toggleTechnique(tech.ID, div));
                container.appendChild(div);
            });
        }

        function toggleTechnique(id, element) {
            if (selectedTechniques.has(id)) {
                selectedTechniques.delete(id);
                element.classList.remove('selected');
            } else {
                selectedTechniques.add(id);
                element.classList.add('selected');
            }
            document.getElementById('statSelected').textContent = selectedTechniques.size;
        }

        function updateTechniqueDisplay() {
            const items = document.querySelectorAll('.technique-item');
            items.forEach(item => {
                const id = item.querySelector('.technique-id').textContent.trim();
                if (selectedTechniques.has(id)) {
                    item.classList.add('selected');
                } else {
                    item.classList.remove('selected');
                }
            });
            document.getElementById('statSelected').textContent = selectedTechniques.size;
        }

        async function executeAttack() {
            const aptCampaign = document.getElementById('aptCampaign').value;
            const industry = document.getElementById('industryVertical').value;
            const attackMode = document.getElementById('attackMode').value;
            const techniqueCount = document.getElementById('techniqueCount').value;
            if (aptCampaign === 'None' && !industry && selectedTechniques.size === 0 && attackMode === 'Selected') {
                logToTerminal('error', '[ERROR] No techniques selected. Choose APT campaign, industry, or select techniques manually.');
                return;
            }
            const payload = {
                aptCampaign: aptCampaign !== 'None' ? aptCampaign : null,
                industry: industry || null,
                attackMode: attackMode,
                techniqueCount: parseInt(techniqueCount),
                selectedTechniques: Array.from(selectedTechniques)
            };
            try {
                logToTerminal('info', '[MAGNETO] Initiating attack sequence...');
                document.getElementById('btnExecute').disabled = true;
                document.getElementById('btnStop').disabled = false;
                document.getElementById('statStatus').textContent = 'RUNNING';
                isRunning = true;
                const response = await fetch('/api/execute', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload)
                });
                const result = await response.json();
                if (result.success) {
                    logToTerminal('success', result.message);
                } else {
                    logToTerminal('error', '[ERROR] ' + result.message);
                }
            } catch (error) {
                logToTerminal('error', '[ERROR] Execution failed: ' + error.message);
                resetExecutionState();
            }
        }

        async function stopExecution() {
            try {
                const response = await fetch('/api/stop', { method: 'POST' });
                const result = await response.json();
                logToTerminal('warning', '[MAGNETO] Stopping execution...');
                resetExecutionState();
            } catch (error) {
                logToTerminal('error', '[ERROR] Failed to stop: ' + error.message);
            }
        }

        async function generateReport() {
            try {
                logToTerminal('info', '[REPORT] Generating HTML report...');
                const response = await fetch('/api/report');
                const result = await response.json();
                if (result.success) {
                    logToTerminal('success', '[REPORT] Generated: ' + result.reportPath);
                    window.open('/api/view-report', '_blank');
                } else {
                    logToTerminal('error', '[ERROR] ' + result.message);
                }
            } catch (error) {
                logToTerminal('error', '[ERROR] Report generation failed: ' + error.message);
            }
        }

        function resetExecutionState() {
            document.getElementById('btnExecute').disabled = false;
            document.getElementById('btnStop').disabled = true;
            document.getElementById('statStatus').textContent = 'READY';
            isRunning = false;
        }

        function logToTerminal(type, message) {
            const terminal = document.getElementById('terminalOutput');
            const line = document.createElement('div');
            line.className = 'terminal-line log-' + type;
            const timestamp = new Date().toLocaleTimeString();
            line.textContent = '[' + timestamp + '] ' + message;
            terminal.appendChild(line);
            terminal.scrollTop = terminal.scrollHeight;
            while (terminal.children.length > 200) {
                terminal.removeChild(terminal.firstChild);
            }
        }

        async function startStatusPolling() {
            setInterval(async () => {
                if (!isRunning) return;
                try {
                    const response = await fetch('/api/status');
                    const data = await response.json();
                    if (data.output && data.output.length > 0) {
                        data.output.forEach(line => {
                            if (line.includes('[+]')) {
                                logToTerminal('success', line);
                            } else if (line.includes('[!]') || line.includes('ERROR')) {
                                logToTerminal('error', line);
                            } else if (line.includes('[>]')) {
                                logToTerminal('command', line);
                            } else {
                                logToTerminal('info', line);
                            }
                        });
                    }
                    if (data.executed !== undefined) {
                        document.getElementById('statExecuted').textContent = data.executed;
                    }
                    if (data.isRunning === false && isRunning) {
                        logToTerminal('success', '[MAGNETO] Execution completed');
                        resetExecutionState();
                    }
                } catch (error) {}
            }, 1000);
        }
    </script>
</body>
</html>
"@
    return $html
}

function Send-HTTPResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [string]$Content,
        [string]$ContentType = "text/html",
        [int]$StatusCode = 200
    )
    $Response.StatusCode = $StatusCode
    $Response.ContentType = "$ContentType; charset=utf-8"
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $Response.ContentLength64 = $buffer.Length
    $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Response.OutputStream.Close()
}

function Send-JSONResponse {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [hashtable]$Data,
        [int]$StatusCode = 200
    )
    $json = $Data | ConvertTo-Json -Depth 10
    Send-HTTPResponse -Response $Response -Content $json -ContentType "application/json" -StatusCode $StatusCode
}

function Handle-GetTechniques {
    param([System.Net.HttpListenerResponse]$Response)
    $data = @{
        success = $true
        techniques = $script:techniques
        count = $script:techniques.Count
    }
    Send-JSONResponse -Response $Response -Data $data
}

function Handle-ExecuteAttack {
    param(
        [System.Net.HttpListenerResponse]$Response,
        [string]$RequestBody
    )
    try {
        $payload = $RequestBody | ConvertFrom-Json
        $magnetoArgs = @()
        if ($payload.aptCampaign) {
            $magnetoArgs += "-APTCampaign"
            $magnetoArgs += $payload.aptCampaign
        }
        elseif ($payload.industry) {
            $magnetoArgs += "-IndustryVertical"
            $magnetoArgs += "`"$($payload.industry)`""
        }
        elseif ($payload.attackMode -eq "Random") {
            $magnetoArgs += "-AttackMode"
            $magnetoArgs += "Random"
            $magnetoArgs += "-TechniqueCount"
            $magnetoArgs += $payload.techniqueCount
        }
        $magnetoArgs += "-Cleanup"
        $scriptBlock = {
            param($ScriptPath, $Args)
            & $ScriptPath @Args
        }
        $script:currentJob = Start-Job -ScriptBlock $scriptBlock -ArgumentList $script:magnetoScriptPath, $magnetoArgs
        $script:isRunning = $true
        Write-ColorOutput "[+] Attack execution started - Job ID: $($script:currentJob.Id)" -Color Green
        $data = @{
            success = $true
            message = "[MAGNETO] Attack execution initiated"
            jobId = $script:currentJob.Id
        }
        Send-JSONResponse -Response $Response -Data $data
    }
    catch {
        $data = @{
            success = $false
            message = "Execution failed: $($_.Exception.Message)"
        }
        Send-JSONResponse -Response $Response -Data $data -StatusCode 500
    }
}

function Handle-StopExecution {
    param([System.Net.HttpListenerResponse]$Response)
    if ($script:currentJob) {
        Stop-Job -Job $script:currentJob -ErrorAction SilentlyContinue
        Remove-Job -Job $script:currentJob -Force -ErrorAction SilentlyContinue
        $script:currentJob = $null
    }
    $script:isRunning = $false
    $data = @{
        success = $true
        message = "Execution stopped"
    }
    Send-JSONResponse -Response $Response -Data $data
}

function Handle-GetStatus {
    param([System.Net.HttpListenerResponse]$Response)
    $output = @()
    $executedCount = 0
    if ($script:currentJob) {
        $jobOutput = Receive-Job -Job $script:currentJob -Keep
        if ($jobOutput) {
            $output = $jobOutput | ForEach-Object { $_.ToString() }
        }
        if ($script:currentJob.State -eq 'Completed' -or $script:currentJob.State -eq 'Failed') {
            $script:isRunning = $false
        }
    }
    $data = @{
        isRunning = $script:isRunning
        output = $output
        executed = $executedCount
    }
    Send-JSONResponse -Response $Response -Data $data
}

function Handle-GenerateReport {
    param([System.Net.HttpListenerResponse]$Response)
    $logDir = Join-Path $PSScriptRoot "MAGNETO_Logs"
    if (Test-Path $logDir) {
        $latestLog = Get-ChildItem -Path $logDir -Filter "*.html" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latestLog) {
            $data = @{
                success = $true
                message = "Report found"
                reportPath = $latestLog.FullName
            }
        } else {
            $data = @{
                success = $false
                message = "No reports found. Execute an attack first."
            }
        }
    } else {
        $data = @{
            success = $false
            message = "Log directory not found"
        }
    }
    Send-JSONResponse -Response $Response -Data $data
}

function Handle-ViewReport {
    param([System.Net.HttpListenerResponse]$Response)
    $logDir = Join-Path $PSScriptRoot "MAGNETO_Logs"
    $latestLog = Get-ChildItem -Path $logDir -Filter "*.html" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestLog) {
        $content = Get-Content -Path $latestLog.FullName -Raw
        Send-HTTPResponse -Response $Response -Content $content -ContentType "text/html"
    } else {
        Send-HTTPResponse -Response $Response -Content "<h1>No report available</h1>" -ContentType "text/html" -StatusCode 404
    }
}

function Start-MagnetoWebServer {
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════" -Color Green
    Write-ColorOutput "         MAGNETO v3 - WEB INTERFACE SERVER                " -Color Green
    Write-ColorOutput "         100% PowerShell | Modern Design                  " -Color Green
    Write-ColorOutput "═══════════════════════════════════════════════════════════" -Color Green
    Write-Host ""
    $script:techniques = Load-Techniques
    if ($script:techniques.Count -eq 0) {
        Write-ColorOutput "[!] WARNING: No techniques loaded. Check MAGNETO_v3.ps1 path." -Color Red
    }
    $url = "$BindAddress`:$Port/"
    try {
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add($url)
        $listener.Start()
        Write-ColorOutput "[+] Web server started successfully!" -Color Green
        Write-ColorOutput "[>] URL: $url" -Color Cyan
        Write-ColorOutput "[>] Press Ctrl+C to stop the server" -Color Yellow
        Write-Host ""
        Start-Process $url
        Write-ColorOutput "[*] Waiting for requests..." -Color Cyan
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            $timestamp = Get-Date -Format "HH:mm:ss"
            Write-ColorOutput "[$timestamp] $($request.HttpMethod) $($request.Url.PathAndQuery)" -Color Magenta
            try {
                switch ($request.Url.AbsolutePath) {
                    "/" {
                        $html = Get-HTMLContent
                        Send-HTTPResponse -Response $response -Content $html
                    }
                    "/api/techniques" {
                        Handle-GetTechniques -Response $response
                    }
                    "/api/execute" {
                        if ($request.HttpMethod -eq "POST") {
                            $reader = New-Object System.IO.StreamReader($request.InputStream)
                            $body = $reader.ReadToEnd()
                            $reader.Close()
                            Handle-ExecuteAttack -Response $response -RequestBody $body
                        }
                    }
                    "/api/stop" {
                        if ($request.HttpMethod -eq "POST") {
                            Handle-StopExecution -Response $response
                        }
                    }
                    "/api/status" {
                        Handle-GetStatus -Response $response
                    }
                    "/api/report" {
                        Handle-GenerateReport -Response $response
                    }
                    "/api/view-report" {
                        Handle-ViewReport -Response $response
                    }
                    default {
                        Send-HTTPResponse -Response $response -Content "404 Not Found" -StatusCode 404
                    }
                }
            }
            catch {
                Write-ColorOutput "[!] Error handling request: $($_.Exception.Message)" -Color Red
                Send-HTTPResponse -Response $response -Content "Internal Server Error" -StatusCode 500
            }
        }
    }
    catch {
        Write-Host ""
        Write-ColorOutput "[!] Error: $($_.Exception.Message)" -Color Red
        if ($_.Exception.Message -like "*access is denied*") {
            Write-Host ""
            Write-ColorOutput "[!] Access denied. Try one of these solutions:" -Color Yellow
            Write-ColorOutput "    1. Run PowerShell as Administrator" -Color Yellow
            Write-ColorOutput "    2. Use a different port: .\MAGNETO_WEB_SERVER.ps1 -Port 8888" -Color Yellow
        }
    }
    finally {
        if ($listener -and $listener.IsListening) {
            $listener.Stop()
            $listener.Close()
            Write-Host ""
            Write-ColorOutput "[+] Server stopped." -Color Green
        }
    }
}

Start-MagnetoWebServer
