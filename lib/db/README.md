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