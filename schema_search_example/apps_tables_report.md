# Schema and Table Analysis Report
## ModelContextProtocol (MCP)

Based on the analysis of a sample codebase, we've identified several applications and their database schemas. This report provides a summary of the major applications and their table structures.

## 1. E-Commerce Platform (ecom-app)

**Schema: ecommerce**

The E-Commerce application manages products, orders, and customer information.

### Main Tables:
- **products**: Core product information
- **product_categories**: Categories for products
- **inventory**: Product inventory levels
- **orders**: Customer orders
- **order_items**: Line items for orders
- **customers**: Customer information
- **shopping_carts**: Active shopping carts
- **promotions**: Sales and discount information
- **price_history**: Historical price changes

### Views:
- **product_inventory_view**: Combined view of products and inventory
- **order_summary_view**: Aggregated order information

## 2. Content Management System (cms-app)

**Schema: cms**

The CMS application manages website content.

### Main Tables:
- **pages**: Website page content
- **media**: Images, videos, and documents
- **templates**: Page templates
- **menus**: Navigation menus
- **users**: CMS users
- **roles**: User role definitions
- **permissions**: Role permissions

### Views:
- **published_content_view**: All published content
- **user_permissions_view**: User and permission mapping

## 3. Customer Service Application (support-app)

**Schema: support**

Manages customer support tickets and communication.

### Main Tables:
- **tickets**: Support tickets
- **ticket_comments**: Comments on tickets
- **ticket_status_history**: Status changes for tickets
- **agents**: Support personnel
- **knowledge_base**: Support articles
- **canned_responses**: Predefined responses
- **customer_communications**: Email and chat history

### Views:
- **open_tickets_view**: All currently open tickets
- **agent_performance_view**: Metrics for support agents

## 4. User Management System (auth-app)

**Schema: auth**

Centralized user authentication and authorization.

### Main Tables:
- **users**: Core user information
- **roles**: Role definitions
- **user_roles**: Mapping between users and roles
- **permissions**: Permission definitions
- **role_permissions**: Mapping between roles and permissions
- **sessions**: User session information
- **login_history**: History of login attempts

### Views:
- **user_permissions_view**: User and permission mapping
- **active_sessions_view**: Currently active user sessions

## 5. Analytics Platform (analytics-app)

**Schema: analytics**

Collects and processes analytics data.

### Main Tables:
- **events**: Raw event data
- **page_views**: Website page view statistics
- **user_sessions**: User browsing sessions
- **conversion_funnel**: Conversion milestone tracking
- **campaign_metrics**: Marketing campaign results
- **referrers**: Traffic sources
- **device_stats**: User device information

### Views:
- **daily_metrics_view**: Daily aggregated metrics
- **conversion_rate_view**: Conversion rates by source

## Summary

The codebase contains several interconnected applications that manage different aspects of an enterprise system:

1. **E-Commerce** (ecom-app): Manages products, inventory, and orders
2. **Content Management** (cms-app): Manages website content
3. **Customer Service** (support-app): Handles support tickets and customer communications
4. **User Management** (auth-app): Centralizes user authentication and authorization
5. **Analytics** (analytics-app): Tracks user activity and business metrics

These applications share common concepts like users, products, and permissions, but each has specialized tables for its specific functionality.
