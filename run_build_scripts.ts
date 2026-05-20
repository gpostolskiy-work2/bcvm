
import { execSync } from 'child_process';
import path from 'path';
import { existsSync } from 'fs';

const isArm = process.argv.includes('--arm');
const noYals = process.argv.includes('--no-yals');
const buildArg = isArm ? ' --arm' : '';

function getBashCommand(): string {
    if (process.platform !== 'win32') {
        return 'bash';
    }
    // Check common Git Bash locations
    const paths = [
        'C:\\Program Files\\Git\\bin\\bash.exe',
        'C:\\Program Files\\Git\\usr\\bin\\bash.exe',
        'C:\\Program Files (x86)\\Git\\bin\\bash.exe',
        'C:\\Git\\bin\\bash.exe'
    ];
    for (const p of paths) {
        if (existsSync(p)) {
            return `"${p}"`;
        }
    }
    // Try to find bash/sh in PATH, but avoid WSL's C:\Windows\System32\bash.exe
    try {
        const whereBash = execSync('where bash', { encoding: 'utf8' }).split('\r\n');
        for (const wb of whereBash) {
            const trimmed = wb.trim();
            if (trimmed && !trimmed.toLowerCase().includes('windows\\system32')) {
                return `"${trimmed}"`;
            }
        }
    } catch (e) {}
    
    try {
        const whereSh = execSync('where sh', { encoding: 'utf8' }).split('\r\n');
        for (const ws of whereSh) {
            const trimmed = ws.trim();
            if (trimmed) {
                return `"${trimmed}"`;
            }
        }
    } catch (e) {}

    return 'bash'; // fallback
}

const bashCmd = getBashCommand();

function runBuild(dir: string) {
    console.log(`\n--- Running build.sh in ${dir}${buildArg} ---`);
    const fullPath = path.join(process.cwd(), dir);
    if (!existsSync(path.join(fullPath, 'build.sh'))) {
        console.error(`Error: build.sh not found in ${dir}`);
        return;
    }
    try {
        execSync(`${bashCmd} build.sh${buildArg}`, { 
            cwd: fullPath,
            stdio: 'inherit',
            env: { ...process.env }
        });
    } catch (e) {
        console.error(`Error building in ${dir}`);
    }
}

runBuild('cpp_system/bcvm');
if (!noYals) {
    runBuild('cpp_system/yals');
}
runBuild('cpp_system/asn');
