-- Additional types and functions for the chat application

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to get current authenticated user ID
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
    SELECT 
        CASE
            WHEN current_setting('request.jwt.claims', true)::json->'sub' IS NOT NULL THEN 
                (current_setting('request.jwt.claims', true)::json->>'sub')::uuid
            ELSE NULL::uuid
        END
$$;

-- Create visibility type enum if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'visibility_type') THEN
        CREATE TYPE public.visibility_type AS ENUM ('private', 'public');
    END IF;
END $$;

-- Function to get all public chats
CREATE OR REPLACE FUNCTION public.get_public_chats()
RETURNS SETOF public."Chat"
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT * FROM public."Chat"
    WHERE visibility = 'public'
    ORDER BY "createdAt" DESC;
$$;

-- Function to get user's chats
CREATE OR REPLACE FUNCTION public.get_user_chats()
RETURNS SETOF public."Chat"
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT * FROM public."Chat"
    WHERE "userId" = auth.uid()
    ORDER BY "createdAt" DESC;
$$;

-- Function to get chat messages
CREATE OR REPLACE FUNCTION public.get_chat_messages(chat_id uuid)
RETURNS TABLE(
    id uuid,
    role varchar,
    content jsonb,
    "createdAt" timestamp,
    "chatId" uuid
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT m.id, m.role, m.content, m."createdAt", m."chatId"
    FROM public."Message" m
    JOIN public."Chat" c ON c.id = m."chatId"
    WHERE m."chatId" = chat_id
    AND (c."userId" = auth.uid() OR c.visibility = 'public')
    ORDER BY m."createdAt" ASC;
$$;

-- Function to get message content
CREATE OR REPLACE FUNCTION public.get_message_content(message_id uuid)
RETURNS TABLE(
    id uuid,
    type public.message_content_type,
    content jsonb,
    "order" integer,
    "createdAt" timestamp,
    "messageId" uuid
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT mc.id, mc.type, mc.content, mc."order", mc."createdAt", mc."messageId"
    FROM public."MessageContent" mc
    JOIN public."Message" m ON m.id = mc."messageId"
    JOIN public."Chat" c ON c.id = m."chatId"
    WHERE mc."messageId" = message_id
    AND (c."userId" = auth.uid() OR c.visibility = 'public')
    ORDER BY mc."order" ASC;
$$;

-- Function to create a new chat
CREATE OR REPLACE FUNCTION public.create_chat(title text, visibility varchar DEFAULT 'private')
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_chat_id uuid;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    INSERT INTO public."Chat" (id, "createdAt", title, "userId", visibility)
    VALUES (uuid_generate_v4(), NOW(), title, auth.uid(), visibility)
    RETURNING id INTO new_chat_id;
    
    RETURN new_chat_id;
END;
$$;

-- Function to update chat visibility
CREATE OR REPLACE FUNCTION public.update_chat_visibility(chat_id uuid, new_visibility varchar)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    affected_rows integer;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    UPDATE public."Chat" 
    SET visibility = new_visibility
    WHERE id = chat_id AND "userId" = auth.uid();
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows > 0;
END;
$$;

-- Create trigger to update chat title based on first message if empty
CREATE OR REPLACE FUNCTION public.update_chat_title_from_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.role = 'user' THEN
        UPDATE public."Chat"
        SET title = SUBSTRING(CAST(NEW.content->>'text' AS TEXT) FROM 1 FOR 50) || '...'
        WHERE id = NEW."chatId"
        AND title = 'New Chat';
    END IF;
    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER trigger_update_chat_title
AFTER INSERT ON public."Message"
FOR EACH ROW
EXECUTE FUNCTION public.update_chat_title_from_message(); 