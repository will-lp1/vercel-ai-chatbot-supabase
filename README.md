# Next.js Ai-Chat with Supabase

This is a chat application template built with Next.js and Supabase, providing a modern UI for conversations with AI assistants.

## Features

- Real-time chat interface
- Model selector for different AI models
- Public/private visibility for chats
- Document management
- Suggestions system
- User authentication via Supabase Auth
- Row-level security for data protection

## Tech Stack

- **Frontend**: Next.js, React, Tailwind CSS
- **Backend**: Supabase (PostgreSQL, Auth)
- **Styling**: Tailwind CSS

## Getting Started

### Prerequisites

- Supabase CLI installed (for local development)
- A Supabase project (for production)

### Setting Up the Project

1. Clone this repository

```bash
git clone <https://github.com/will-lp1/vercel-ai-chatbot-supabase.git>
cd <repository-name>
```

2. Install dependencies

```
pnpm install
```

3. Set up Supabase locally

```bash
supabase init
supabase start
```

4. Copy the environment variables

```bash
cp .env.example .env.local
```

5. Update the `.env.local` file with your Supabase URL and anon key (found in the Supabase dashboard or from the local setup)

6. Run the development server

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application running.

## Database Structure

The application uses the following tables in Supabase:

- `Chat`: Stores chat conversations
- `Message`: Stores individual messages in chats
- `MessageContent`: Stores different types of content within messages
- `Document`: Stores document information
- `Suggestion`: Stores suggestions for document improvements
- `Vote`: Tracks user votes on messages

See the `supabase/README.md` file for more details on the database structure and migration files.

## Authentication

The application uses Supabase Auth for user authentication. Users can:

- Sign up with email and password
- Log in with existing credentials
- Access their own chats and documents

## Deployment

### Deploying the Frontend

You can deploy the Next.js application to Vercel:

1. Push your code to a GitHub repository
2. Import the project in Vercel
3. Set the environment variables (from your Supabase project)
4. Deploy

### Setting Up the Database

There are multiple ways to set up the database for this application:

#### Option 1: Using Supabase CLI (Recommended for Development)

1. Create a Supabase project
2. Link your local project to the Supabase project:

```bash
supabase link --project-ref your-project-ref
```

3. Push the migrations:

```bash
supabase db push
```

#### Option 2: Using Supabase SQL Editor Directly

1. Navigate to your Supabase project dashboard
2. Go to the SQL Editor tab
3. Copy the contents of the migration files from either:
   - `supabase/migrations/*.sql` files
   - `lib/db/migrations/*.sql` files
4. Paste and execute these SQL files in order in the SQL Editor

For example, first execute `20240601000000_initial_schema.sql`, then `20240601000001_functions_and_types.sql`.

#### Option 3: Using supabase-mcp-server with AI Coding Tools

For a seamless setup experience, you can use the [supabase-mcp-server](https://github.com/alexander-zuev/supabase-mcp-server) with AI coding tools to:

1. Follow the setup 
2. Connect to your Supabase project through the server
3. Have the AI assistant analyze the migration files and apply them to your project

This approach is particularly useful when working with AI coding IDEs, like Windsurf and Cursor, that can help automate the setup process and ensure all migrations are applied correctly.

## Project Structure

- `/app`: Next.js app router files
- `/components`: React components
- `/lib`: Utility functions and shared code
- `/public`: Static assets
- `/supabase`: Supabase configuration and migrations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
