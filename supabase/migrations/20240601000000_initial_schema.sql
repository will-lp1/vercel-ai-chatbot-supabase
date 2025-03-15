-- Create the initial schema for the chat application
-- This migration sets up all tables required for the application

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom type for message content types
CREATE TYPE public.message_content_type AS ENUM ('text', 'code', 'tool_call', 'tool_result', 'image', 'system');

-- Chat table: Stores information about chat conversations
CREATE TABLE public."Chat" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
    title TEXT NOT NULL,
    "userId" UUID NOT NULL,
    visibility VARCHAR NOT NULL DEFAULT 'private',
    
    -- Create foreign key reference to auth.users
    CONSTRAINT fk_user_id
        FOREIGN KEY ("userId")
        REFERENCES auth.users(id)
        ON DELETE CASCADE
);

-- Message table: Stores messages within chats
CREATE TABLE public."Message" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "chatId" UUID NOT NULL,
    role VARCHAR NOT NULL,
    content JSONB NOT NULL,
    "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Create foreign key reference to Chat
    CONSTRAINT fk_chat_id
        FOREIGN KEY ("chatId")
        REFERENCES public."Chat"(id)
        ON DELETE CASCADE
);

-- MessageContent table: Stores different types of content within messages
CREATE TABLE public."MessageContent" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "messageId" UUID NOT NULL,
    type message_content_type NOT NULL,
    content JSONB NOT NULL,
    "order" INTEGER NOT NULL,
    "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Create foreign key reference to Message
    CONSTRAINT fk_message_id
        FOREIGN KEY ("messageId")
        REFERENCES public."Message"(id)
        ON DELETE CASCADE
);

-- Document table: Stores document information
CREATE TABLE public."Document" (
    id UUID PRIMARY KEY,
    "createdAt" TIMESTAMP NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    kind VARCHAR NOT NULL DEFAULT 'text',
    "userId" UUID NOT NULL,
    
    -- Set combined primary key
    PRIMARY KEY (id, "createdAt"),
    
    -- Create foreign key reference to auth.users
    CONSTRAINT fk_user_id
        FOREIGN KEY ("userId")
        REFERENCES auth.users(id)
        ON DELETE CASCADE
);

-- Suggestion table: Stores suggestions related to documents
CREATE TABLE public."Suggestion" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    "documentId" UUID NOT NULL,
    "documentCreatedAt" TIMESTAMP NOT NULL,
    "originalText" TEXT NOT NULL,
    "suggestedText" TEXT NOT NULL,
    description TEXT,
    "isResolved" BOOLEAN NOT NULL DEFAULT false,
    "userId" UUID NOT NULL,
    "createdAt" TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Create foreign key reference to Document
    CONSTRAINT fk_document
        FOREIGN KEY ("documentId", "documentCreatedAt")
        REFERENCES public."Document"(id, "createdAt")
        ON DELETE CASCADE,
        
    -- Create foreign key reference to auth.users
    CONSTRAINT fk_user_id
        FOREIGN KEY ("userId")
        REFERENCES auth.users(id)
        ON DELETE CASCADE
);

-- Vote table: Stores user votes on messages
CREATE TABLE public."Vote" (
    "chatId" UUID NOT NULL,
    "messageId" UUID NOT NULL,
    "isUpvoted" BOOLEAN NOT NULL,
    "userId" UUID,
    
    -- Set combined primary key
    PRIMARY KEY ("chatId", "messageId"),
    
    -- Create foreign key references
    CONSTRAINT fk_chat_id
        FOREIGN KEY ("chatId")
        REFERENCES public."Chat"(id)
        ON DELETE CASCADE,
        
    CONSTRAINT fk_message_id
        FOREIGN KEY ("messageId")
        REFERENCES public."Message"(id)
        ON DELETE CASCADE,
        
    CONSTRAINT fk_user_id
        FOREIGN KEY ("userId")
        REFERENCES auth.users(id)
        ON DELETE SET NULL
);

-- Create indexes for better query performance
CREATE INDEX idx_chat_user_id ON public."Chat" ("userId");
CREATE INDEX idx_message_chat_id ON public."Message" ("chatId");
CREATE INDEX idx_message_content_message_id ON public."MessageContent" ("messageId");
CREATE INDEX idx_document_user_id ON public."Document" ("userId");
CREATE INDEX idx_suggestion_document_id ON public."Suggestion" ("documentId", "documentCreatedAt");
CREATE INDEX idx_suggestion_user_id ON public."Suggestion" ("userId");

-- Create Row Level Security (RLS) policies
-- Enable RLS on all tables
ALTER TABLE public."Chat" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Message" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."MessageContent" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Document" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Suggestion" ENABLE ROW LEVEL SECURITY;
ALTER TABLE public."Vote" ENABLE ROW LEVEL SECURITY;

-- Chat policies
CREATE POLICY "Users can view their own chats"
    ON public."Chat"
    FOR SELECT
    TO authenticated
    USING ("userId" = auth.uid());

CREATE POLICY "Users can view public chats"
    ON public."Chat"
    FOR SELECT
    TO authenticated
    USING (visibility = 'public');

CREATE POLICY "Users can insert their own chats"
    ON public."Chat"
    FOR INSERT
    TO authenticated
    WITH CHECK ("userId" = auth.uid());

CREATE POLICY "Users can update their own chats"
    ON public."Chat"
    FOR UPDATE
    TO authenticated
    USING ("userId" = auth.uid());

CREATE POLICY "Users can delete their own chats"
    ON public."Chat"
    FOR DELETE
    TO authenticated
    USING ("userId" = auth.uid());

-- Message policies
CREATE POLICY "Users can view messages in their chats"
    ON public."Message"
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public."Chat"
            WHERE public."Chat".id = "chatId"
            AND (public."Chat"."userId" = auth.uid() OR public."Chat".visibility = 'public')
        )
    );

CREATE POLICY "Users can insert messages in their chats"
    ON public."Message"
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public."Chat"
            WHERE public."Chat".id = "chatId"
            AND public."Chat"."userId" = auth.uid()
        )
    );

-- MessageContent policies
CREATE POLICY "Users can view message content in their chats"
    ON public."MessageContent"
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public."Message"
            JOIN public."Chat" ON public."Chat".id = public."Message"."chatId"
            WHERE public."Message".id = "messageId"
            AND (public."Chat"."userId" = auth.uid() OR public."Chat".visibility = 'public')
        )
    );

CREATE POLICY "Users can insert message content in their chats"
    ON public."MessageContent"
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public."Message"
            JOIN public."Chat" ON public."Chat".id = public."Message"."chatId"
            WHERE public."Message".id = "messageId"
            AND public."Chat"."userId" = auth.uid()
        )
    );

-- Document policies
CREATE POLICY "Users can view their own documents"
    ON public."Document"
    FOR SELECT
    TO authenticated
    USING ("userId" = auth.uid());

CREATE POLICY "Users can insert their own documents"
    ON public."Document"
    FOR INSERT
    TO authenticated
    WITH CHECK ("userId" = auth.uid());

CREATE POLICY "Users can update their own documents"
    ON public."Document"
    FOR UPDATE
    TO authenticated
    USING ("userId" = auth.uid());

CREATE POLICY "Users can delete their own documents"
    ON public."Document"
    FOR DELETE
    TO authenticated
    USING ("userId" = auth.uid());

-- Suggestion policies
CREATE POLICY "Users can view suggestions for their documents"
    ON public."Suggestion"
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public."Document"
            WHERE public."Document".id = "documentId"
            AND public."Document"."createdAt" = "documentCreatedAt"
            AND public."Document"."userId" = auth.uid()
        )
    );

CREATE POLICY "Users can insert suggestions for documents"
    ON public."Suggestion"
    FOR INSERT
    TO authenticated
    WITH CHECK ("userId" = auth.uid());

CREATE POLICY "Users can update their own suggestions"
    ON public."Suggestion"
    FOR UPDATE
    TO authenticated
    USING ("userId" = auth.uid());

-- Vote policies
CREATE POLICY "Users can view votes"
    ON public."Vote"
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public."Chat"
            WHERE public."Chat".id = "chatId"
            AND (public."Chat"."userId" = auth.uid() OR public."Chat".visibility = 'public')
        )
    );

CREATE POLICY "Users can insert their own votes"
    ON public."Vote"
    FOR INSERT
    TO authenticated
    WITH CHECK ("userId" = auth.uid());

CREATE POLICY "Users can update their own votes"
    ON public."Vote"
    FOR UPDATE
    TO authenticated
    USING ("userId" = auth.uid());

CREATE POLICY "Users can delete their own votes"
    ON public."Vote"
    FOR DELETE
    TO authenticated
    USING ("userId" = auth.uid()); 