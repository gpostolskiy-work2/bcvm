
import { execSync } from 'child_process';
import { existsSync, mkdirSync, rmSync, createWriteStream } from 'fs';
import { homedir, arch } from 'os';
import { get } from 'https';
import path from 'path';

const INSTALL_DIR = `${homedir()}/local/gpp`;
const TEMP_DIR = `${homedir()}/.gpp-tmp`;

function hasGpp(): boolean {
    const checkCommand = (cmd: string) => {
        try { execSync(`${cmd} --version`, { stdio: 'ignore' }); return true; } 
        catch { return false; }
    };

    if (checkCommand('g++') && checkCommand('cmake') && checkCommand('make')) {
        return true;
    }
    
    // Also check if conda bin is already in PATH or if miniconda exists
    const condaBin = path.join(homedir(), 'miniconda3', 'bin');
    if (existsSync(path.join(condaBin, 'g++')) || existsSync(path.join(condaBin, 'x86_64-conda-linux-gnu-g++'))) {
        process.env.PATH = `${condaBin}:${process.env.PATH}`;
        if (checkCommand('g++') && checkCommand('cmake') && checkCommand('make')) {
            return true;
        }
    }
    return false; 
}

function download(url: string, dest: string): Promise<void> {
    return new Promise((resolve, reject) => {
        const file = createWriteStream(dest);
        const options = {
            headers: {
                'User-Agent': 'Mozilla/5.0'
            }
        };
        get(url, options, res => {
            if (res.statusCode !== 200) {
                reject(new Error(`Failed to download: ${res.statusCode}`));
                return;
            }
            res.pipe(file);
            file.on('finish', () => {
                file.close();
                resolve();
            });
        }).on('error', err => {
            file.close();
            reject(err);
        });
    });
}

async function installViaConda(): Promise<boolean> {
    console.log('📦 Starting installation via Conda...');
    const url = arch() === 'x64' 
        ? 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
        : 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh';
    
    const installer = path.join(TEMP_DIR, 'miniconda.sh');
    if (!existsSync(TEMP_DIR)) mkdirSync(TEMP_DIR, { recursive: true });
    
    console.log(`📥 Downloading installer from ${url}...`);
    await download(url, installer);
    console.log('✅ Download complete.');

    console.log('⚙️ Installing Miniconda to ~/miniconda3...');
    execSync(`bash ${installer} -b -p ${homedir()}/miniconda3 -f`);
    
    console.log('🔧 Installing gxx_linux-64 and cmake via Conda...');
    // We need to use the full path to conda initially
    const condaPath = `${homedir()}/miniconda3/bin/conda`;
    
    try {
        console.log('📜 Accepting Terms of Service...');
        execSync(`${condaPath} tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true`);
        execSync(`${condaPath} tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || true`);
    } catch (e) {
        console.log('⚠️ Could not accept TOS, continuing anyway...');
    }
    
    execSync(`${condaPath} install -c conda-forge gxx_linux-64 cmake make -y`);
    
    const condaBin = path.join(homedir(), 'miniconda3', 'bin');
    const prefixedGpp = path.join(condaBin, 'x86_64-conda-linux-gnu-g++');
    const standardGpp = path.join(condaBin, 'g++');
    
    if (existsSync(prefixedGpp) && !existsSync(standardGpp)) {
        console.log('🔗 Creating symlink for g++...');
        try {
            execSync(`ln -s ${prefixedGpp} ${standardGpp}`);
        } catch (e) {
            console.log('⚠️ Could not create symlink');
        }
    }

    process.env.PATH = `${condaBin}:${process.env.PATH}`;
    console.log('✅ g++ установлен через Conda');
    return true;
}

async function main(): Promise<void> {
    if (hasGpp()) { 
        console.log('✅ g++ уже есть или путь обновлен.'); 
        return; 
    }
    console.log('🔧 Установка g++...');
    try {
        await installViaConda();
    } finally {
        if (existsSync(TEMP_DIR)) {
            rmSync(TEMP_DIR, { recursive: true, force: true });
        }
    }
}

main().catch(e => {
    console.error('❌ Ошибка:', e.message);
    process.exit(1);
});
