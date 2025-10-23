DROP INDEX `species_name_unique`;--> statement-breakpoint
PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_supplies` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`unit` text,
	`on_hand_qty` real DEFAULT 0,
	`cost_per_unit` real,
	`vendor` text,
	`lot` text,
	`expires_at` integer,
	`low_stock_threshold` real,
	`notes` text
);
--> statement-breakpoint
INSERT INTO `__new_supplies`("id", "name", "unit", "on_hand_qty", "cost_per_unit", "vendor", "lot", "expires_at", "low_stock_threshold", "notes") SELECT "id", "name", "unit", "on_hand_qty", "cost_per_unit", "vendor", "lot", "expires_at", "low_stock_threshold", "notes" FROM `supplies`;--> statement-breakpoint
DROP TABLE `supplies`;--> statement-breakpoint
ALTER TABLE `__new_supplies` RENAME TO `supplies`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
CREATE TABLE `__new_users` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`username` text NOT NULL,
	`email` text NOT NULL,
	`password_hash` text,
	`role` text DEFAULT 'user',
	`timezone` text DEFAULT 'UTC',
	`units` text DEFAULT 'metric',
	`default_spawn_ratio` real DEFAULT 0.2,
	`api_token` text,
	`created_at` integer DEFAULT CURRENT_TIMESTAMP
);
--> statement-breakpoint
INSERT INTO `__new_users`("id", "username", "email", "password_hash", "role", "timezone", "units", "default_spawn_ratio", "api_token", "created_at") SELECT "id", "username", "email", "password_hash", "role", "timezone", "units", "default_spawn_ratio", "api_token", "created_at" FROM `users`;--> statement-breakpoint
DROP TABLE `users`;--> statement-breakpoint
ALTER TABLE `__new_users` RENAME TO `users`;--> statement-breakpoint
CREATE TABLE `__new_grow_events` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`grow_id` integer NOT NULL,
	`kind` text NOT NULL,
	`happened_at` integer,
	`note` text,
	`photo_url` text
);
--> statement-breakpoint
INSERT INTO `__new_grow_events`("id", "grow_id", "kind", "happened_at", "note", "photo_url") SELECT "id", "grow_id", "kind", "happened_at", "note", "photo_url" FROM `grow_events`;--> statement-breakpoint
DROP TABLE `grow_events`;--> statement-breakpoint
ALTER TABLE `__new_grow_events` RENAME TO `grow_events`;--> statement-breakpoint
CREATE TABLE `__new_grows` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`strain_id` integer,
	`recipe_id` integer,
	`culture_id` integer,
	`tek` text,
	`vessel` text,
	`vessel_count` integer,
	`substrate_weight_g` real,
	`spawn_ratio` real,
	`status` text,
	`planned_at` integer,
	`inoculated_at` integer,
	`fruiting_at` integer,
	`completed_at` integer,
	`notes` text
);
--> statement-breakpoint
INSERT INTO `__new_grows`("id", "strain_id", "recipe_id", "culture_id", "tek", "vessel", "vessel_count", "substrate_weight_g", "spawn_ratio", "status", "planned_at", "inoculated_at", "fruiting_at", "completed_at", "notes") SELECT "id", "strain_id", "recipe_id", "culture_id", "tek", "vessel", "vessel_count", "substrate_weight_g", "spawn_ratio", "status", "planned_at", "inoculated_at", "fruiting_at", "completed_at", "notes" FROM `grows`;--> statement-breakpoint
DROP TABLE `grows`;--> statement-breakpoint
ALTER TABLE `__new_grows` RENAME TO `grows`;--> statement-breakpoint
CREATE TABLE `__new_recipes` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`type` text NOT NULL,
	`instructions` text,
	`version` integer DEFAULT 1,
	`is_default` integer DEFAULT false NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_recipes`("id", "name", "type", "instructions", "version", "is_default") SELECT "id", "name", "type", "instructions", "version", "is_default" FROM `recipes`;--> statement-breakpoint
DROP TABLE `recipes`;--> statement-breakpoint
ALTER TABLE `__new_recipes` RENAME TO `recipes`;--> statement-breakpoint
CREATE TABLE `__new_shopping_items` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`supply_id` integer,
	`needed_qty` real,
	`added_at` integer,
	`resolved_at` integer,
	`notes` text
);
--> statement-breakpoint
INSERT INTO `__new_shopping_items`("id", "supply_id", "needed_qty", "added_at", "resolved_at", "notes") SELECT "id", "supply_id", "needed_qty", "added_at", "resolved_at", "notes" FROM `shopping_items`;--> statement-breakpoint
DROP TABLE `shopping_items`;--> statement-breakpoint
ALTER TABLE `__new_shopping_items` RENAME TO `shopping_items`;--> statement-breakpoint
CREATE TABLE `__new_strains` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`species_id` integer,
	`name` text NOT NULL,
	`origin` text,
	`notes` text,
	`image_url` text
);
--> statement-breakpoint
INSERT INTO `__new_strains`("id", "species_id", "name", "origin", "notes", "image_url") SELECT "id", "species_id", "name", "origin", "notes", "image_url" FROM `strains`;--> statement-breakpoint
DROP TABLE `strains`;--> statement-breakpoint
ALTER TABLE `__new_strains` RENAME TO `strains`;--> statement-breakpoint
CREATE TABLE `__new_tasks` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`user_id` integer,
	`grow_id` integer,
	`title` text,
	`due_at` integer,
	`done_at` integer,
	`notes` text,
	`priority` integer
);
--> statement-breakpoint
INSERT INTO `__new_tasks`("id", "user_id", "grow_id", "title", "due_at", "done_at", "notes", "priority") SELECT "id", "user_id", "grow_id", "title", "due_at", "done_at", "notes", "priority" FROM `tasks`;--> statement-breakpoint
DROP TABLE `tasks`;--> statement-breakpoint
ALTER TABLE `__new_tasks` RENAME TO `tasks`;--> statement-breakpoint
CREATE TABLE `__new_yields` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`grow_id` integer NOT NULL,
	`flush_number` integer DEFAULT 1,
	`wet_g` real,
	`dry_g` real,
	`harvested_at` integer,
	`notes` text
);
--> statement-breakpoint
INSERT INTO `__new_yields`("id", "grow_id", "flush_number", "wet_g", "dry_g", "harvested_at", "notes") SELECT "id", "grow_id", "flush_number", "wet_g", "dry_g", "harvested_at", "notes" FROM `yields`;--> statement-breakpoint
DROP TABLE `yields`;--> statement-breakpoint
ALTER TABLE `__new_yields` RENAME TO `yields`;