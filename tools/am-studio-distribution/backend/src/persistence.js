import fs from 'node:fs';
import path from 'node:path';

export class JsonFilePersistence {
  constructor(filePath = process.env.AM_STATE_FILE || path.resolve('var/am-studio-state.json')) {
    this.filePath = filePath;
  }

  load() {
    if (!fs.existsSync(this.filePath)) return null;
    const raw = fs.readFileSync(this.filePath, 'utf8');
    if (!raw.trim()) return null;
    return JSON.parse(raw);
  }

  save(snapshot) {
    const dir = path.dirname(this.filePath);
    fs.mkdirSync(dir, { recursive: true });
    const temp = `${this.filePath}.${process.pid}.tmp`;
    fs.writeFileSync(temp, JSON.stringify(snapshot, null, 2), { encoding: 'utf8', mode: 0o600 });
    fs.renameSync(temp, this.filePath);
  }
}

export class NullPersistence {
  load() { return null; }
  save() {}
}
