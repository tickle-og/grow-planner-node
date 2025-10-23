import { sqliteTable, integer, text, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  username: text('username').notNull(),
  email: text('email').notNull(),
  passwordHash: text('password_hash'),
  role: text('role').default('user'),
  timezone: text('timezone').default('UTC'),
  units: text('units').default('metric'),
  defaultSpawnRatio: real('default_spawn_ratio').default(0.2),
  apiToken: text('api_token'),
  createdAt: integer('created_at', { mode: 'timestamp' }).default(sql`CURRENT_TIMESTAMP`),
});

export const species = sqliteTable('species', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  notes: text('notes'),
});

export const strains = sqliteTable('strains', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  speciesId: integer('species_id'),
  name: text('name').notNull(),
  origin: text('origin'),
  notes: text('notes'),
  imageUrl: text('image_url'),
});

export const recipes = sqliteTable('recipes', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  type: text('type').notNull(), // 'substrate' | 'agar' | 'lc'
  instructions: text('instructions'),
  version: integer('version').default(1),
  isDefault: integer('is_default', { mode: 'boolean' }).default(false).notNull(),
});

export const recipeIngredients = sqliteTable('recipe_ingredients', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  recipeId: integer('recipe_id').notNull(),
  itemName: text('item_name').notNull(),
  unit: text('unit').notNull(),
  qty: real('qty').notNull(),
});

export const supplies = sqliteTable('supplies', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull(),
  unit: text('unit'),
  onHandQty: real('on_hand_qty').default(0),
  costPerUnit: real('cost_per_unit'),
  vendor: text('vendor'),
  lot: text('lot'),
  expiresAt: integer('expires_at', { mode: 'timestamp' }),
  lowStockThreshold: real('low_stock_threshold'),
  notes: text('notes'),
});

export const grows = sqliteTable('grows', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  strainId: integer('strain_id'),
  recipeId: integer('recipe_id'),
  cultureId: integer('culture_id'),
  tek: text('tek'),
  vessel: text('vessel'),
  vesselCount: integer('vessel_count'),
  substrateWeightG: real('substrate_weight_g'),
  spawnRatio: real('spawn_ratio'),
  status: text('status'),
  plannedAt: integer('planned_at', { mode: 'timestamp' }),
  inoculatedAt: integer('inoculated_at', { mode: 'timestamp' }),
  fruitingAt: integer('fruiting_at', { mode: 'timestamp' }),
  completedAt: integer('completed_at', { mode: 'timestamp' }),
  notes: text('notes'),
});

export const growEvents = sqliteTable('grow_events', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  growId: integer('grow_id').notNull(),
  kind: text('kind').notNull(), // plan, inoculate, shake, transfer, harvest, ...
  happenedAt: integer('happened_at', { mode: 'timestamp' }),
  note: text('note'),
  photoUrl: text('photo_url'),
});

export const yields = sqliteTable('yields', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  growId: integer('grow_id').notNull(),
  flushNumber: integer('flush_number').default(1),
  wetG: real('wet_g'),
  dryG: real('dry_g'),
  harvestedAt: integer('harvested_at', { mode: 'timestamp' }),
  notes: text('notes'),
});

export const tasks = sqliteTable('tasks', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id'),
  growId: integer('grow_id'),
  title: text('title'),
  dueAt: integer('due_at', { mode: 'timestamp' }),
  doneAt: integer('done_at', { mode: 'timestamp' }),
  notes: text('notes'),
  priority: integer('priority'),
});

export const shoppingItems = sqliteTable('shopping_items', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  supplyId: integer('supply_id'),
  neededQty: real('needed_qty'),
  addedAt: integer('added_at', { mode: 'timestamp' }),
  resolvedAt: integer('resolved_at', { mode: 'timestamp' }),
  notes: text('notes'),
});

export const auditLog = sqliteTable('audit_log', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id'),
  action: text('action').notNull(),
  entity: text('entity').notNull(),
  entityId: integer('entity_id'),
  createdAt: integer('created_at', { mode: 'timestamp' }).default(sql`CURRENT_TIMESTAMP`),
});
