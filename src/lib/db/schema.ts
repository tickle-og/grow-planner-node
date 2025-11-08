// src/lib/db/schema.ts
import { sqliteTable, integer, text, real } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

/**
 * USERS
 * - basic auth-ish fields plus role flagging and activity timestamps
 */
export const users = sqliteTable(
	'users',
	{
		id: integer('id').primaryKey({ autoIncrement: true }),
		username: text('username').notNull(),
		email: text('email').notNull(),
		passwordHash: text('password_hash').notNull(),

		roleGlobal: text('role_global').default('member'), // e.g., 'admin' | 'member'
		isActive: integer('is_active', { mode: 'boolean' }).notNull().default(true),

		lastLoginAt: text('last_login_at'),
		createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
		updatedAt: text('updated_at')
	},
	(t) => ({
		usernameUq: sql`CREATE UNIQUE INDEX IF NOT EXISTS users_username_uq ON users(username)`,
		emailUq: sql`CREATE UNIQUE INDEX IF NOT EXISTS users_email_uq ON users(email)`
	})
);

/**
 * LOCATIONS
 * - named place for grows/shelves; members define access
 */
export const locations = sqliteTable('locations', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	ownerUserId: integer('owner_user_id')
		.notNull()
		.references(() => users.id),
	name: text('name').notNull(),
	nickname: text('nickname'),
	timezone: text('timezone').default('UTC'),
	isActive: integer('is_active', { mode: 'boolean' }).notNull().default(true),

	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
	updatedAt: text('updated_at')
});

/**
 * LOCATION MEMBERS
 * - who can access a location + role at that location
 */
export const locationMembers = sqliteTable(
	'location_members',
	{
		id: integer('id').primaryKey({ autoIncrement: true }),
		locationId: integer('location_id')
			.notNull()
			.references(() => locations.id),
		userId: integer('user_id')
			.notNull()
			.references(() => users.id),
		memberRole: text('member_role').default('member'), // 'owner' | 'manager' | 'member' etc.
		createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`)
	},
	(t) => ({
		locUserUnique: sql`CREATE UNIQUE INDEX IF NOT EXISTS location_members_loc_user_uq ON location_members(location_id, user_id)`,
		byUserIdx: sql`CREATE INDEX IF NOT EXISTS location_members_user_idx ON location_members(user_id)`
	})
);

/**
 * LOCATION SHELVES
 * - physical shelves to help plan capacity; dimensions in cm, levels for stacked tiers
 */
export const locationShelves = sqliteTable('location_shelves', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	label: text('label').notNull(),

	lengthCm: integer('length_cm'),
	widthCm: integer('width_cm'),
	heightCm: integer('height_cm'),
	levels: integer('levels').default(1),

	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`)
});

/**
 * SHELF BINS
 * - optional child containers on a shelf; help track asset locations
 */
export const shelfBins = sqliteTable('shelf_bins', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	shelfId: integer('shelf_id').references(() => locationShelves.id),

	label: text('label').notNull(),
	capacityCm2: integer('capacity_cm2'),

	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`)
});

/**
 * BIN ASSIGNMENTS
 * - assign grows (single items or groups) to bins; track placement/removal
 */
export const binAssignments = sqliteTable('bin_assignments', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	binId: integer('bin_id')
		.notNull()
		.references(() => shelfBins.id),
	growId: integer('grow_id').references(() => grows.id),

	groupLabel: text('group_label'),
	notes: text('notes'),

	placedAt: text('placed_at').default(sql`CURRENT_TIMESTAMP`),
	removedAt: text('removed_at')
});

/**
 * CONTAINER PRESETS
 * - catalog of preset containers (monotub, bag, tray, etc.)
 * - defaultsJson is a TEXT column named 'defaults' that stores JSON
 */
export const containerPresets = sqliteTable('container_presets', {
	key: text('key').primaryKey(),
	containerType: text('container_type').notNull(), // 'monotub' | 'tray' | 'bag' | 'jar' ...
	label: text('label').notNull(),
	defaultsJson: text('defaults'), // JSON string (e.g., { length_cm, width_cm, height_cm, ... })
	active: integer('active', { mode: 'boolean' }).notNull().default(true)
});

/**
 * JAR VARIANTS
 * - common mason jar sizes and geometry
 */
export const jarVariants = sqliteTable('jar_variants', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	label: text('label').notNull(),
	sizeMl: integer('size_ml'),
	mouth: text('mouth'), // 'wide' | 'narrow'
	heightMm: integer('height_mm'),
	diameterMm: integer('diameter_mm')
});

/**
 * CULTURES
 * - strains/species/etc. to seed grows
 */
export const cultures = sqliteTable('cultures', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	createdByUserId: integer('created_by_user_id').references(() => users.id),

	name: text('name').notNull(), // display name
	species: text('species'),
	variety: text('variety'),
	vendor: text('vendor'),
	lotCode: text('lot_code'),
	origin: text('origin'),
	notes: text('notes'),

	isPublic: integer('is_public', { mode: 'boolean' }).default(false),

	acquiredAt: text('acquired_at'),
	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
	updatedAt: text('updated_at')
});

/**
 * RECIPES
 * - grain/substrate recipes etc.
 * - ingredients can be JSON text
 */
export const recipes = sqliteTable('recipes', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	createdByUserId: integer('created_by_user_id').references(() => users.id),

	name: text('name').notNull(),
	recipeType: text('recipe_type'), // 'grain' | 'substrate' | 'liquid_culture' ...
	ingredients: text('ingredients'), // JSON string
	hydrationPct: real('hydration_pct'),
	sterilizationMethod: text('sterilization_method'), // 'PC' | 'steam' | 'UHT' ...
	sterilizationMinutes: integer('sterilization_minutes'),
	sterilizationTempC: real('sterilization_temp_c'),
	spawnRatio: real('spawn_ratio'),
	tek: text('tek'),
	description: text('description'),
	notes: text('notes'),

	isPublic: integer('is_public', { mode: 'boolean' }).default(false),

	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
	updatedAt: text('updated_at')
});

/**
 * SUPPLIES / INVENTORY
 */
export const supplies = sqliteTable('supplies', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	createdByUserId: integer('created_by_user_id').references(() => users.id),

	name: text('name').notNull(),
	sku: text('sku'),
	category: text('category'),
	description: text('description'),
	preferredSupplier: text('preferred_supplier'),
	locationLabel: text('location_label'),

	inStockQty: integer('in_stock_qty').default(0),
	reorderPoint: integer('reorder_point').default(0),
	unitCost: real('unit_cost'),

	isActive: integer('is_active', { mode: 'boolean' }).notNull().default(true),

	lastRestockedAt: text('last_restocked_at'),
	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
	updatedAt: text('updated_at')
});

/**
 * GROWS
 * - central process record; many optional lifecycle timestamps
 * - containerConfigJson is JSON TEXT named 'container_config'
 */
export const grows = sqliteTable('grows', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	createdByUserId: integer('created_by_user_id').references(() => users.id),

	cultureId: integer('culture_id').references(() => cultures.id),
	recipeId: integer('recipe_id').references(() => recipes.id),

	status: text('status'), // 'planning' | 'incubating' | 'fruiting' | 'complete' | 'contaminated' | 'retired' | ...
	batchCode: text('batch_code'),
	inoculationMethod: text('inoculation_method'),

	containerType: text('container_type'), // 'monotub' | 'tray' | 'bag' | 'jar' ...
	containerPresetKey: text('container_preset_key').references(() => containerPresets.key),
	containerConfigJson: text('container_config'), // JSON string for dimensions/options

	environmentJson: text('environment'), // JSON string (temps/humidity/etc.)
	notes: text('notes'),

	startDate: text('start_date'),
	inoculationDate: text('inoculation_date'),
	spawnWeightG: real('spawn_weight_g'),
	incubationStartAt: text('incubation_start_at'),
	colonizationCompleteAt: text('colonization_complete_at'),
	movedToFruitingAt: text('moved_to_fruiting_at'),

	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
	updatedAt: text('updated_at')
});

/**
 * YIELD DATA
 * - per-flush harvest info + optional notes
 */
export const yieldData = sqliteTable('yield_data', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id),
	growId: integer('grow_id')
		.notNull()
		.references(() => grows.id),

	flushNumber: integer('flush_number').default(1),
	harvestDate: text('harvest_date'),

	wetWeightG: real('wet_weight_g'),
	dryWeightG: real('dry_weight_g'),

	capSizeAvgMm: real('cap_size_avg_mm'),
	stipeLengthAvgMm: real('stipe_length_avg_mm'),
	qualityGrade: text('quality_grade'), // A/B/C … or custom
	contaminated: integer('contamination_flag', { mode: 'boolean' }),

	notes: text('notes'),

	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`)
});

/** Tasks: time-based actions for dashboard/calendar */
export const tasks = sqliteTable('tasks', {
	id: integer('id').primaryKey({ autoIncrement: true }),
	locationId: integer('location_id')
		.notNull()
		.references(() => locations.id, { onDelete: 'cascade' }),
	growId: integer('grow_id').references(() => grows.id, { onDelete: 'set null' }),
	title: text('title').notNull(),
	status: text('status')
		.$type<'pending' | 'active' | 'completed' | 'failed'>()
		.notNull()
		.default('pending'),
	dueAt: text('due_at'),
	notes: text('notes'),
	createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
	updatedAt: text('updated_at')
});
