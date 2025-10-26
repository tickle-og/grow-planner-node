// src/lib/db/schema.ts
import { sqliteTable, integer, text, real, uniqueIndex } from "drizzle-orm/sqlite-core";
import { sql } from "drizzle-orm";

/** =========================
 *  Core
 *  ========================= */
export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  username: text("username").notNull().unique(),
  email: text("email").notNull().unique(),
  passwordHash: text("password_hash").notNull(),
  roleGlobal: text("role_global").notNull().default("user"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  lastLoginAt: text("last_login_at"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});

/** =========================
 *  Locations & Access
 *  ========================= */
export const locations = sqliteTable("locations", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  ownerUserId: integer("owner_user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  nickname: text("nickname"),
  description: text("description"),
  timezone: text("timezone"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});

export const locationMembers = sqliteTable(
  "location_members",
  {
    id: integer("id").primaryKey({ autoIncrement: true }),
    locationId: integer("location_id")
      .notNull()
      .references(() => locations.id, { onDelete: "cascade" }),
    userId: integer("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    memberRole: text("member_role").notNull().default("viewer"), // owner|manager|worker|viewer
    createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`)
  },
  (t) => ({
    uqLocationMemberPair: uniqueIndex("uq_location_member_pair").on(t.locationId, t.userId)
  })
);

export const locationShelves = sqliteTable("location_shelves", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  lengthCm: real("length_cm").notNull(),
  widthCm: real("width_cm").notNull(),
  heightCm: real("height_cm").notNull(),
  levels: integer("levels").default(1),
  notes: text("notes")
});

/** =========================
 *  Container Catalogs
 *  ========================= */
export const containerPresets = sqliteTable("container_presets", {
  key: text("key").primaryKey(),
  containerType: text("container_type").notNull(), // jar|bag|monotub|tray|bottle|other
  label: text("label").notNull(),
  defaultsJson: text("defaults", { mode: "json" }).notNull(),
  active: integer("active", { mode: "boolean" }).notNull().default(true)
});

export const jarVariants = sqliteTable("jar_variants", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  label: text("label").notNull(),
  sizeMl: integer("size_ml").notNull(),
  mouth: text("mouth").notNull(), // wide|narrow
  heightMm: integer("height_mm"),
  diameterMm: integer("diameter_mm")
});

/** =========================
 *  Domain (Location-scoped)
 *  ========================= */
export const cultures = sqliteTable("cultures", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  createdByUserId: integer("created_by_user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  species: text("species").notNull(),
  strain: text("strain"),
  cultureType: text("culture_type").notNull().default("plate"), // slant|plate|liquid_culture|spore_print|spore_syringe|tissue_clone|agar_plate
  source: text("source"),
  medium: text("medium"),
  storageTempC: real("storage_temp_c"),
  storageLocation: text("storage_location"),
  status: text("status").notNull().default("active"), // active|stored|retired|contaminated
  notes: text("notes"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});

export const recipes = sqliteTable("recipes", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  createdByUserId: integer("created_by_user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  recipeType: text("recipe_type").notNull().default("substrate"), // grain|substrate|casing|liquid_culture|supplement
  ingredientsJson: text("ingredients", { mode: "json" }).notNull(),
  hydrationPct: real("hydration_pct"),
  sterilizationMethod: text("sterilization_method"),
  sterilizationMinutes: integer("sterilization_minutes"),
  sterilizationTempC: real("sterilization_temp_c"),
  spawnRatio: real("spawn_ratio"),
  tek: text("tek"),
  instructions: text("instructions"),
  isPublic: integer("is_public", { mode: "boolean" }).notNull().default(false),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});

export const supplies = sqliteTable("supplies", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  createdByUserId: integer("created_by_user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  sku: text("sku"),
  name: text("name").notNull(),
  category: text("category").notNull().default("other"), // grain|substrate|supplement|lab_consumable|packaging|equipment|other
  description: text("description"),
  unit: text("unit"),
  inStockQty: real("in_stock_qty").notNull().default(0),
  reorderPoint: real("reorder_point").notNull().default(0),
  costPerUnit: real("cost_per_unit"),
  preferredSupplier: text("preferred_supplier"),
  locationLabel: text("location_label"),
  lastRestockedAt: text("last_restocked_at"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});

export const grows = sqliteTable("grows", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  createdByUserId: integer("created_by_user_id").notNull().references(() => users.id, { onDelete: "cascade" }),

  cultureId: integer("culture_id").references(() => cultures.id, { onDelete: "set null" }),
  recipeId: integer("recipe_id").references(() => recipes.id, { onDelete: "set null" }),

  // container-aware config
  containerType: text("container_type").notNull(), // jar|bag|monotub|tray|bottle|other
  containerPresetKey: text("container_preset_key"),
  containerConfigJson: text("container_config", { mode: "json" }),

  // metadata
  tek: text("tek"),
  batchCode: text("batch_code"),
  inoculationMethod: text("inoculation_method"),

  // timeline
  startDate: text("start_date"),
  inoculationDate: text("inoculation_date"),
  spawnWeightG: real("spawn_weight_g"),
  substrateWeightG: real("substrate_weight_g"),
  incubationStartAt: text("incubation_start_at"),
  colonizationCompleteAt: text("colonization_complete_at"),
  movedToFruitingAt: text("moved_to_fruiting_at"),

  // state
  status: text("status").notNull().default("planning"),
  environmentJson: text("environment", { mode: "json" }),
  notes: text("notes"),

  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});

export const yieldData = sqliteTable("yield_data", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  growId: integer("grow_id").notNull().references(() => grows.id, { onDelete: "cascade" }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  flushNumber: integer("flush_number").notNull().default(1),
  harvestDate: text("harvest_date"),
  wetWeightG: real("wet_weight_g"),
  dryWeightG: real("dry_weight_g"),
  potencyEstimateMgPerG: real("potency_estimate_mg_per_g"),
  bioEfficiencyPct: real("bio_efficiency_pct"),
  discardWeightG: real("discard_weight_g"),
  notes: text("notes"),
  createdAt: text("created_at").notNull().default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at").notNull().default(sql`CURRENT_TIMESTAMP`)
});
