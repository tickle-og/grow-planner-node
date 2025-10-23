CREATE TABLE `audit_log` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`user_id` integer,
	`action` text NOT NULL,
	`entity` text NOT NULL,
	`entity_id` integer,
	`created_at` integer DEFAULT CURRENT_TIMESTAMP
);
--> statement-breakpoint
CREATE TABLE `grow_events` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`grow_id` integer NOT NULL,
	`kind` text NOT NULL,
	`happened_at` integer NOT NULL,
	`note` text,
	`photo_url` text
);
--> statement-breakpoint
CREATE TABLE `grows` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`strain_id` integer NOT NULL,
	`recipe_id` integer NOT NULL,
	`culture_id` integer,
	`tek` text NOT NULL,
	`vessel` text NOT NULL,
	`vessel_count` integer DEFAULT 1 NOT NULL,
	`substrate_weight_g` real DEFAULT 0 NOT NULL,
	`spawn_ratio` real DEFAULT 0.2 NOT NULL,
	`status` text DEFAULT 'planned' NOT NULL,
	`planned_at` integer,
	`inoculated_at` integer,
	`fruiting_at` integer,
	`completed_at` integer,
	`notes` text
);
--> statement-breakpoint
CREATE TABLE `recipe_ingredients` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`recipe_id` integer NOT NULL,
	`item_name` text NOT NULL,
	`unit` text NOT NULL,
	`qty` real NOT NULL
);
--> statement-breakpoint
CREATE TABLE `shopping_items` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`supply_id` integer NOT NULL,
	`needed_qty` real DEFAULT 0 NOT NULL,
	`added_at` integer DEFAULT CURRENT_TIMESTAMP,
	`resolved_at` integer,
	`notes` text
);
--> statement-breakpoint
CREATE TABLE `species` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`notes` text
);
--> statement-breakpoint
CREATE UNIQUE INDEX `species_name_unique` ON `species` (`name`);--> statement-breakpoint
CREATE TABLE `strains` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`species_id` integer NOT NULL,
	`name` text NOT NULL,
	`origin` text,
	`notes` text,
	`image_url` text
);
--> statement-breakpoint
CREATE TABLE `supplies` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`unit` text NOT NULL,
	`on_hand_qty` real DEFAULT 0 NOT NULL,
	`cost_per_unit` real DEFAULT 0 NOT NULL,
	`vendor` text,
	`lot` text,
	`expires_at` integer,
	`low_stock_threshold` real DEFAULT 0,
	`notes` text
);
--> statement-breakpoint
CREATE UNIQUE INDEX `supplies_name_unique` ON `supplies` (`name`);--> statement-breakpoint
CREATE TABLE `users` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`username` text NOT NULL,
	`email` text NOT NULL,
	`password_hash` text NOT NULL,
	`role` text DEFAULT 'user' NOT NULL,
	`timezone` text DEFAULT 'UTC',
	`units` text DEFAULT 'metric',
	`default_spawn_ratio` real DEFAULT 0.2,
	`api_token` text,
	`created_at` integer DEFAULT CURRENT_TIMESTAMP
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_username_unique` ON `users` (`username`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
DROP TABLE `batches`;--> statement-breakpoint
DROP TABLE `logs`;--> statement-breakpoint
PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_recipes` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`type` text NOT NULL,
	`instructions` text,
	`version` integer DEFAULT 1 NOT NULL,
	`is_default` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_recipes`("id", "name", "type", "instructions", "version", "is_default") SELECT "id", "name", "type", "instructions", "version", "is_default" FROM `recipes`;--> statement-breakpoint
DROP TABLE `recipes`;--> statement-breakpoint
ALTER TABLE `__new_recipes` RENAME TO `recipes`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
CREATE TABLE `__new_tasks` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`user_id` integer NOT NULL,
	`grow_id` integer,
	`title` text NOT NULL,
	`due_at` integer,
	`done_at` integer,
	`notes` text,
	`priority` integer DEFAULT 0
);
--> statement-breakpoint
INSERT INTO `__new_tasks`("id", "user_id", "grow_id", "title", "due_at", "done_at", "notes", "priority") SELECT "id", "user_id", "grow_id", "title", "due_at", "done_at", "notes", "priority" FROM `tasks`;--> statement-breakpoint
DROP TABLE `tasks`;--> statement-breakpoint
ALTER TABLE `__new_tasks` RENAME TO `tasks`;--> statement-breakpoint
CREATE TABLE `__new_yields` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`grow_id` integer NOT NULL,
	`flush_number` integer DEFAULT 1 NOT NULL,
	`wet_g` real DEFAULT 0 NOT NULL,
	`dry_g` real DEFAULT 0 NOT NULL,
	`harvested_at` integer,
	`notes` text
);
--> statement-breakpoint
INSERT INTO `__new_yields`("id", "grow_id", "flush_number", "wet_g", "dry_g", "harvested_at", "notes") SELECT "id", "grow_id", "flush_number", "wet_g", "dry_g", "harvested_at", "notes" FROM `yields`;--> statement-breakpoint
DROP TABLE `yields`;--> statement-breakpoint
ALTER TABLE `__new_yields` RENAME TO `yields`;