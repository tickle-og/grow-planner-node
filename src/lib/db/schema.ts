// src/lib/db/schema.ts
import { sqliteTable, text, integer, blob } from 'drizzle-orm/sqlite-core';
import { createId } from '@paralleldrive/cuid2';

export const batches = sqliteTable('batches', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  name: text('name').notNull(),
  recipeId: text('recipe_id').notNull(),
  qtyUnits: integer('qty_units').notNull(),
  stage: text('stage').notNull().default('plan'),
  startDate: integer('start_date').notNull(), // epoch ms
  targetHarvestDate: integer('target_harvest_date'),
  locationId: text('location_id'),
  notes: text('notes'),
  createdAt: integer('created_at').notNull(),
  updatedAt: integer('updated_at').notNull()
});

export const recipes = sqliteTable('recipes', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  name: text('name').notNull(),
  version: integer('version').notNull().default(1),
  description: text('description'),
  defaultScale: integer('default_scale').notNull().default(1),
  media: text('media_json').notNull(),
  steps: text('steps_json').notNull(),
  createdAt: integer('created_at').notNull(),
  updatedAt: integer('updated_at').notNull()
});

export const tasks = sqliteTable('tasks', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  batchId: text('batch_id').notNull(),
  title: text('title').notNull(),
  dueAt: integer('due_at').notNull(),
  durationMin: integer('duration_min'),
  status: text('status').notNull().default('open'), // open | done | snoozed
  stepKey: text('step_key'),
  notes: text('notes'),
  createdAt: integer('created_at').notNull(),
  updatedAt: integer('updated_at').notNull()
});

export const logs = sqliteTable('logs', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  batchId: text('batch_id').notNull(),
  kind: text('kind').notNull(), // 'note' | 'env' | 'photo'
  payload: text('payload_json'),
  photo: blob('photo_blob'),
  createdAt: integer('created_at').notNull()
});

export const yieldsTbl = sqliteTable('yields', {
  id: text('id').primaryKey().$defaultFn(() => createId()),
  batchId: text('batch_id').notNull(),
  flushNo: integer('flush_no').notNull().default(1),
  wetWeightG: integer('wet_weight_g').notNull(),
  dryWeightG: integer('dry_weight_g'),
  notes: text('notes'),
  createdAt: integer('created_at').notNull()
});
