// tighten this as your auth matures
declare global {
  namespace App {
    interface Locals {
      user?: { id: number; username?: string; role?: string };
    }
  }
}
export {};
