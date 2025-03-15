# Supabase Setup Guide

This directory contains the Supabase configuration for the chat application, including database migrations.

## Database Migrations

The database schema is defined in the `migrations` directory. The migrations set up the following tables:

1. `Chat`: Stores information about chat conversations
2. `Message`: Stores messages within chats
3. `MessageContent`: Stores different types of content within messages
4. `Document`: Stores document information
5. `Suggestion`: Stores suggestions related to documents
6. `Vote`: Stores user votes on messages

## Getting Started with Supabase CLI

1. **Install Supabase CLI**

   Follow the instructions at [Supabase CLI Documentation](https://supabase.com/docs/guides/cli) to install the CLI on your system.

2. **Setup Local Development**

   Initialize Supabase locally:

   ```bash
   supabase init
   ```

3. **Start Supabase Locally**

   ```bash
   supabase start
   ```

4. **Run Migrations**

   The migrations will be applied automatically when you start Supabase. If you want to apply them manually:

   ```bash
   supabase db reset
   ```

## Deploying to Production

1. **Link to Your Supabase Project**

   ```bash
   supabase link --project-ref your-project-ref
   ```

2. **Push the Migrations to Production**

   ```bash
   supabase db push
   ```

## Alternative Ways to Apply Migrations

### Using Supabase SQL Editor Directly

If you prefer to apply the migrations manually:

1. Navigate to your Supabase project dashboard
2. Go to the SQL Editor tab
3. Copy the contents of the migration files from the `migrations` directory
4. Paste and execute these SQL files in order in the SQL Editor

For example, first execute `20240601000000_initial_schema.sql`, then `20240601000001_functions_and_types.sql`.

### Using supabase-mcp-server with AI Coding Tools

For a seamless setup experience, you can use the [supabase-mcp-server](https://github.com/alexander-zuev/supabase-mcp-server) with AI coding tools:

1. Install the supabase-mcp-server:
```bash
npm install -g supabase-mcp-server
```

2. Connect to your Supabase project through the server:
```bash
supabase-mcp-server --project-id your-project-id --api-key your-service-role-key
```

3. Use an AI coding assistant (like Claude, ChatGPT, or GitHub Copilot) to:
   - Analyze your migration files
   - Apply them to your project through the server
   - Verify the database schema

This approach provides a more interactive and guided setup process, especially useful for complex schemas or when you need assistance understanding the database structure.

## Database Schema

### Main Tables

- **Chat**: Represents a conversation between a user and the AI
  - Includes fields for title, visibility, and userId

- **Message**: Represents individual messages within a chat
  - Linked to a Chat via chatId
  - Includes the role (user/assistant) and content

- **MessageContent**: Stores granular content within messages
  - Supports different content types (text, code, tool calls, etc.)
  - Ordered within a message

- **Document**: Stores document information for the application
  - Can contain various types of content based on the 'kind' field

- **Suggestion**: Stores suggestions related to documents
  - Linked to a specific document
  - Contains original text and suggested replacements

- **Vote**: Tracks user votes on messages
  - Combined primary key of chatId and messageId

### Row Level Security (RLS)

All tables have appropriate RLS policies to ensure:
- Users can only view their own chats (or public chats)
- Users can only modify their own content
- Appropriate cascading deletes are set up

## Custom Types

- `message_content_type`: Enum type for different message content types ('text', 'code', 'tool_call', 'tool_result', 'image', 'system') 