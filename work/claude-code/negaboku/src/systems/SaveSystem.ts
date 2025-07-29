import { SaveData, SaveSlot, GameProgress, InventoryItem } from '../types/Save';
import { Character, RelationshipMatrix } from '../types/Character';
import { v4 as uuidv4 } from 'uuid';
import * as fs from 'fs';
import * as path from 'path';

export class SaveSystem {
  private saveDirectory: string;
  private maxSlots: number = 10;

  constructor(saveDirectory: string = './saves') {
    this.saveDirectory = saveDirectory;
    this.ensureSaveDirectory();
  }

  private ensureSaveDirectory(): void {
    if (!fs.existsSync(this.saveDirectory)) {
      fs.mkdirSync(this.saveDirectory, { recursive: true });
    }
  }

  private getSaveFilePath(slotNumber: number): string {
    return path.join(this.saveDirectory, `save_slot_${slotNumber}.json`);
  }

  save(
    slotNumber: number,
    playerName: string,
    playTime: number,
    gameProgress: GameProgress,
    party: Character[],
    relationships: RelationshipMatrix,
    inventory: InventoryItem[],
    clearedDungeons: string[],
    availableDungeons: string[],
    orbs: number,
    gold: number,
    level: number,
    experience: number,
    dlcUnlocked: boolean
  ): boolean {
    try {
      if (slotNumber < 1 || slotNumber > this.maxSlots) {
        throw new Error(`Invalid slot number: ${slotNumber}. Must be between 1 and ${this.maxSlots}.`);
      }

      const saveData: SaveData = {
        id: uuidv4(),
        slotNumber,
        playerName,
        playTime,
        saveDate: new Date(),
        gameProgress,
        party: [...party],
        relationships: { ...relationships },
        inventory: [...inventory],
        clearedDungeons: [...clearedDungeons],
        availableDungeons: [...availableDungeons],
        orbs,
        gold,
        level,
        experience,
        dlcUnlocked
      };

      const filePath = this.getSaveFilePath(slotNumber);
      fs.writeFileSync(filePath, JSON.stringify(saveData, null, 2));
      
      return true;
    } catch (error) {
      console.error('Save failed:', error);
      return false;
    }
  }

  load(slotNumber: number): SaveData | null {
    try {
      if (slotNumber < 1 || slotNumber > this.maxSlots) {
        throw new Error(`Invalid slot number: ${slotNumber}. Must be between 1 and ${this.maxSlots}.`);
      }

      const filePath = this.getSaveFilePath(slotNumber);
      
      if (!fs.existsSync(filePath)) {
        return null;
      }

      const saveDataRaw = fs.readFileSync(filePath, 'utf8');
      const saveData: SaveData = JSON.parse(saveDataRaw);
      
      saveData.saveDate = new Date(saveData.saveDate);
      
      return saveData;
    } catch (error) {
      console.error('Load failed:', error);
      return null;
    }
  }

  deleteSave(slotNumber: number): boolean {
    try {
      if (slotNumber < 1 || slotNumber > this.maxSlots) {
        throw new Error(`Invalid slot number: ${slotNumber}. Must be between 1 and ${this.maxSlots}.`);
      }

      const filePath = this.getSaveFilePath(slotNumber);
      
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        return true;
      }
      
      return false;
    } catch (error) {
      console.error('Delete save failed:', error);
      return false;
    }
  }

  getAllSaveSlots(): SaveSlot[] {
    const slots: SaveSlot[] = [];
    
    for (let i = 1; i <= this.maxSlots; i++) {
      const filePath = this.getSaveFilePath(i);
      const slot: SaveSlot = {
        slotNumber: i,
        isOccupied: fs.existsSync(filePath)
      };

      if (slot.isOccupied) {
        try {
          const saveData = this.load(i);
          if (saveData) {
            slot.saveData = saveData;
            slot.lastModified = saveData.saveDate;
          }
        } catch (error) {
          console.error(`Error loading slot ${i}:`, error);
          slot.isOccupied = false;
        }
      }

      slots.push(slot);
    }

    return slots;
  }

  getEmptySlots(): number[] {
    return this.getAllSaveSlots()
      .filter(slot => !slot.isOccupied)
      .map(slot => slot.slotNumber);
  }

  getOccupiedSlots(): number[] {
    return this.getAllSaveSlots()
      .filter(slot => slot.isOccupied)
      .map(slot => slot.slotNumber);
  }

  copySave(fromSlot: number, toSlot: number): boolean {
    try {
      const saveData = this.load(fromSlot);
      if (!saveData) {
        return false;
      }

      saveData.id = uuidv4();
      saveData.slotNumber = toSlot;
      saveData.saveDate = new Date();

      const toFilePath = this.getSaveFilePath(toSlot);
      fs.writeFileSync(toFilePath, JSON.stringify(saveData, null, 2));
      
      return true;
    } catch (error) {
      console.error('Copy save failed:', error);
      return false;
    }
  }

  exportSave(slotNumber: number, exportPath: string): boolean {
    try {
      const saveData = this.load(slotNumber);
      if (!saveData) {
        return false;
      }

      fs.writeFileSync(exportPath, JSON.stringify(saveData, null, 2));
      return true;
    } catch (error) {
      console.error('Export save failed:', error);
      return false;
    }
  }

  importSave(importPath: string, slotNumber: number): boolean {
    try {
      if (!fs.existsSync(importPath)) {
        return false;
      }

      const saveDataRaw = fs.readFileSync(importPath, 'utf8');
      const saveData: SaveData = JSON.parse(saveDataRaw);
      
      saveData.id = uuidv4();
      saveData.slotNumber = slotNumber;
      saveData.saveDate = new Date();

      const filePath = this.getSaveFilePath(slotNumber);
      fs.writeFileSync(filePath, JSON.stringify(saveData, null, 2));
      
      return true;
    } catch (error) {
      console.error('Import save failed:', error);
      return false;
    }
  }
}