CREATE TABLE `container_presets` (
	`key` text PRIMARY KEY NOT NULL,
	`container_type` text NOT NULL,
	`label` text NOT NULL,
	`defaults` text NOT NULL,
	`active` integer DEFAULT true NOT NULL
);
--> statement-breakpoint
CREATE TABLE `cultures` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`location_id` integer NOT NULL,
	`created_by_user_id` integer NOT NULL,
	`name` text NOT NULL,
	`species` text NOT NULL,
	`strain` text,
	`culture_type` text DEFAULT 'plate' NOT NULL,
	`source` text,
	`medium` text,
	`storage_temp_c` real,
	`storage_location` text,
	`status` text DEFAULT 'active' NOT NULL,
	`notes` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`created_by_user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `grows` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`location_id` integer NOT NULL,
	`created_by_user_id` integer NOT NULL,
	`culture_id` integer,
	`recipe_id` integer,
	`container_type` text NOT NULL,
	`container_preset_key` text,
	`container_config` text,
	`tek` text,
	`batch_code` text,
	`inoculation_method` text,
	`start_date` text,
	`inoculation_date` text,
	`spawn_weight_g` real,
	`substrate_weight_g` real,
	`incubation_start_at` text,
	`colonization_complete_at` text,
	`moved_to_fruiting_at` text,
	`status` text DEFAULT 'planning' NOT NULL,
	`environment` text,
	`notes` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`created_by_user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`culture_id`) REFERENCES `cultures`(`id`) ON UPDATE no action ON DELETE set null,
	FOREIGN KEY (`recipe_id`) REFERENCES `recipes`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE TABLE `jar_variants` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`label` text NOT NULL,
	`size_ml` integer NOT NULL,
	`mouth` text NOT NULL,
	`height_mm` integer,
	`diameter_mm` integer
);
--> statement-breakpoint
CREATE TABLE `location_members` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`location_id` integer NOT NULL,
	`user_id` integer NOT NULL,
	`member_role` text DEFAULT 'viewer' NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `uq_location_member_pair` ON `location_members` (`location_id`,`user_id`);--> statement-breakpoint
CREATE TABLE `location_shelves` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`location_id` integer NOT NULL,
	`name` text NOT NULL,
	`length_cm` real NOT NULL,
	`width_cm` real NOT NULL,
	`height_cm` real NOT NULL,
	`levels` integer DEFAULT 1,
	`notes` text,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `locations` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`owner_user_id` integer NOT NULL,
	`name` text NOT NULL,
	`nickname` text,
	`description` text,
	`timezone` text,
	`is_active` integer DEFAULT true NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`owner_user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `recipes` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`location_id` integer NOT NULL,
	`created_by_user_id` integer NOT NULL,
	`name` text NOT NULL,
	`recipe_type` text DEFAULT 'substrate' NOT NULL,
	`ingredients` text NOT NULL,
	`hydration_pct` real,
	`sterilization_method` text,
	`sterilization_minutes` integer,
	`sterilization_temp_c` real,
	`spawn_ratio` real,
	`tek` text,
	`instructions` text,
	`is_public` integer DEFAULT false NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`created_by_user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `supplies` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`location_id` integer NOT NULL,
	`created_by_user_id` integer NOT NULL,
	`sku` text,
	`name` text NOT NULL,
	`category` text DEFAULT 'other' NOT NULL,
	`description` text,
	`unit` text,
	`in_stock_qty` real DEFAULT 0 NOT NULL,
	`reorder_point` real DEFAULT 0 NOT NULL,
	`cost_per_unit` real,
	`preferred_supplier` text,
	`location_label` text,
	`last_restocked_at` text,
	`is_active` integer DEFAULT true NOT NULL,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`created_by_user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `users` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`username` text NOT NULL,
	`email` text NOT NULL,
	`password_hash` text NOT NULL,
	`role_global` text DEFAULT 'user' NOT NULL,
	`is_active` integer DEFAULT true NOT NULL,
	`last_login_at` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_username_unique` ON `users` (`username`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);--> statement-breakpoint
CREATE TABLE `yield_data` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`grow_id` integer NOT NULL,
	`location_id` integer NOT NULL,
	`flush_number` integer DEFAULT 1 NOT NULL,
	`harvest_date` text,
	`wet_weight_g` real,
	`dry_weight_g` real,
	`potency_estimate_mg_per_g` real,
	`bio_efficiency_pct` real,
	`discard_weight_g` real,
	`notes` text,
	`created_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	`updated_at` text DEFAULT CURRENT_TIMESTAMP NOT NULL,
	FOREIGN KEY (`grow_id`) REFERENCES `grows`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON UPDATE no action ON DELETE cascade
);
