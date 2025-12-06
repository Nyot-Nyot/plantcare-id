"""List all routes in the FastAPI app."""
from main import app

print("All Routes:")
for route in app.routes:
    if hasattr(route, 'path') and hasattr(route, 'methods'):
        methods = ', '.join(sorted(route.methods))
        print(f"  {methods:15} {route.path}")

print("\nCollections Routes:")
collections_routes = [r for r in app.routes if hasattr(r, 'path') and '/collections' in r.path]
for route in collections_routes:
    if hasattr(route, 'methods'):
        methods = ', '.join(sorted(route.methods))
        print(f"  {methods:15} {route.path}")

print(f"\nTotal routes: {len([r for r in app.routes if hasattr(r, 'path')])}")
print(f"Collection routes: {len(collections_routes)}")
