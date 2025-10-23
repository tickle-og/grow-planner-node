CREATE TABLE `batches` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`recipe_id` text NOT NULL,
	`qty_units` integer NOT NULL,
	`stage` text DEFAULT 'plan' NOT NULL,
	`start_date` integer NOT NULL,
	`target_harvest_date` integer,
	`location_id` text,
	`notes` text,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `logs` (
	`id` text PRIMARY KEY NOT NULL,
	`batch_id` text NOT NULL,
	`kind` text NOT NULL,
	`payload_json` text,
	`photo_blob` blob,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `recipes` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`version` integer DEFAULT 1 NOT NULL,
	`description` text,
	`default_scale` integer DEFAULT 1 NOT NULL,
	`media_json` text NOT NULL,
	`steps_json` text NOT NULL,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `tasks` (
	`id` text PRIMARY KEY NOT NULL,
	`batch_id` text NOT NULL,
	`title` text NOT NULL,
	`due_at` integer NOT NULL,
	`duration_min` integer,
	`status` text DEFAULT 'open' NOT NULL,
	`step_key` text,
	`notes` text,
	`created_at` integer NOT NULL,
	`updated_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `yields` (
	`id` text PRIMARY KEY NOT NULL,
	`batch_id` text NOT NULL,
	`flush_no` integer DEFAULT 1 NOT NULL,
	`wet_weight_g` integer NOT NULL,
	`dry_weight_g` integer,
	`notes` text,
	`created_at` integer NOT NULL
);
