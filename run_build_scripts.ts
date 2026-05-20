
import { execSync } from 'child_process';
import path from 'path';
import { existsSync } from 'fs';

const isArm = process.argv.includes('--arm');
const noYals = process.argv.includes('--no-yals');
const buildArg = isArm ? ' --arm' : '';

function runBuild(dir: string) {
    console.log(`\n--- Running build.sh in ${dir}${buildArg} ---`);
    const fullPath = path.join(process.cwd(), dir);
    if (!existsSync(path.join(fullPath, 'build.sh'))) {
        console.error(`Error: build.sh not found in ${dir}`);
        return;
    }
    try {
        execSync(`bash build.sh${buildArg}`, { 
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
