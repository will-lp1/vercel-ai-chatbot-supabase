import type {
  CoreAssistantMessage,
  CoreToolMessage,
  Message,
  TextStreamPart,
  ToolInvocation,
  ToolCall,
  ToolResult,
} from 'ai';
import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

import type { Message as DBMessage, Document } from '@/lib/db/schema';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

interface ApplicationError extends Error {
  info: string;
  status: number;
}

export const fetcher = async (url: string) => {
  const res = await fetch(url);

  if (!res.ok) {
    const error = new Error(
      'An error occurred while fetching the data.',
    ) as ApplicationError;

    error.info = await res.json();
    error.status = res.status;

    throw error;
  }

  return res.json();
};

export function getLocalStorage(key: string) {
  if (typeof window !== 'undefined') {
    return JSON.parse(localStorage.getItem(key) || '[]');
  }
  return [];
}

export function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

function addToolMessageToChat({
  toolMessage,
  messages,
}: {
  toolMessage: CoreToolMessage;
  messages: Array<Message>;
}): Array<Message> {
  return messages.map((message) => {
    if (message.toolInvocations) {
      return {
        ...message,
        toolInvocations: message.toolInvocations.map((toolInvocation) => {
          const toolResult = toolMessage.content.find(
            (tool) => tool.toolCallId === toolInvocation.toolCallId,
          );

          if (toolResult) {
            return {
              ...toolInvocation,
              state: 'result',
              result: toolResult.result,
            };
          }

          return toolInvocation;
        }),
      };
    }

    return message;
  });
}

// Extend ToolInvocation to include result
type ExtendedToolInvocation = ToolInvocation & {
  result?: any;
};

export function convertToUIMessages(
  messages: Array<DBMessage>,
): Array<Message> {
  return messages.reduce((chatMessages: Array<Message>, message) => {
    if (message.role === 'tool') {
      return addToolMessageToChat({
        toolMessage: message as CoreToolMessage,
        messages: chatMessages,
      });
    }

    let textContent = '';
    let reasoning: string | undefined = undefined;
    const toolInvocations: Array<ExtendedToolInvocation> = [];

    if (typeof message.content === 'string') {
      textContent = message.content;
    } else if (Array.isArray(message.content)) {
      for (const content of message.content) {
        if (content.type === 'text') {
          textContent += content.text;
        } else if (content.type === 'tool_call') {
          toolInvocations.push({
            state: 'call',
            toolCallId: content.toolCallId || content.content.toolCallId,
            toolName: content.toolName || content.content.toolName,
            args: content.args || content.content.args,
          });
        } else if (content.type === 'tool_result') {
          // Find matching tool invocation and update it
          const existingInvocation = toolInvocations.find(
            inv => inv.toolCallId === (content.toolCallId || content.content.toolCallId)
          );
          if (existingInvocation) {
            existingInvocation.state = 'result';
            existingInvocation.result = content.result || content.content.result;
          } else {
            // If no matching invocation found, create a new one
            toolInvocations.push({
              state: 'result',
              toolCallId: content.toolCallId || content.content.toolCallId,
              toolName: content.toolName || content.content.toolName,
              args: content.args || content.content.args,
              result: content.result || content.content.result,
            });
          }
        } else if (content.type === 'reasoning') {
          reasoning = content.reasoning || content.content.reasoning;
        }
      }
    }

    chatMessages.push({
      id: message.id,
      role: message.role as Message['role'],
      content: textContent,
      reasoning,
      toolInvocations: toolInvocations.length > 0 ? toolInvocations : undefined,
    });

    return chatMessages;
  }, []);
}

type ResponseMessageWithoutId = CoreToolMessage | CoreAssistantMessage;
type ResponseMessage = ResponseMessageWithoutId & { id: string };

export function sanitizeResponseMessages({
  messages,
  reasoning,
}: {
  messages: Array<ResponseMessage>;
  reasoning: string | undefined;
}) {
  const toolResultIds: Array<string> = [];

  for (const message of messages) {
    if (message.role === 'tool') {
      for (const content of message.content) {
        if (content.type === 'tool-result') {
          toolResultIds.push(content.toolCallId);
        }
      }
    }
  }

  const messagesBySanitizedContent = messages.map((message) => {
    if (message.role !== 'assistant') return message;

    if (typeof message.content === 'string') return message;

    const sanitizedContent = message.content.filter((content) =>
      content.type === 'tool-call'
        ? toolResultIds.includes(content.toolCallId)
        : content.type === 'text'
          ? content.text.length > 0
          : true,
    );

    if (reasoning) {
      // @ts-expect-error: reasoning message parts in sdk is wip
      sanitizedContent.push({ type: 'reasoning', reasoning });
    }

    return {
      ...message,
      content: sanitizedContent,
    };
  });

  return messagesBySanitizedContent.filter(
    (message) => message.content.length > 0,
  );
}

export function sanitizeUIMessages(messages: Array<Message>): Array<Message> {
  const messagesBySanitizedToolInvocations = messages.map((message) => {
    if (message.role !== 'assistant') return message;

    if (!message.toolInvocations) return message;

    const toolResultIds: Array<string> = [];

    for (const toolInvocation of message.toolInvocations) {
      if (toolInvocation.state === 'result') {
        toolResultIds.push(toolInvocation.toolCallId);
      }
    }

    const sanitizedToolInvocations = message.toolInvocations.filter(
      (toolInvocation) =>
        toolInvocation.state === 'result' ||
        toolResultIds.includes(toolInvocation.toolCallId),
    );

    return {
      ...message,
      toolInvocations: sanitizedToolInvocations,
    };
  });

  return messagesBySanitizedToolInvocations.filter(
    (message) =>
      message.content.length > 0 ||
      (message.toolInvocations && message.toolInvocations.length > 0),
  );
}

export function getMostRecentUserMessage(messages: Array<Message>) {
  const userMessages = messages.filter((message) => message.role === 'user');
  return userMessages.at(-1);
}

export function getDocumentTimestampByIndex(
  documents: Array<Document>,
  index: number,
) {
  if (!documents) return new Date();
  if (index > documents.length) return new Date();

  return documents[index].createdAt;
}

interface MessageContent {
  type: 'text' | 'tool_call' | 'tool_result' | 'code' | 'image' | 'system';
  content: any;
  order: number;
}

export function parseMessageContent(content: any): MessageContent[] {
  if (typeof content === 'string') {
    try {
      // Try to parse as JSON first
      const parsed = JSON.parse(content);
      if (Array.isArray(parsed)) {
        return parsed.map((item, index) => {
          // Normalize type names
          const type = (item.type === 'tool-call' ? 'tool_call' : 
                       item.type === 'tool-result' ? 'tool_result' : 
                       item.type || 'text') as MessageContent['type'];
          
          // For tool results, ensure proper structure
          if (type === 'tool_result') {
            return {
              type,
              content: {
                type: 'tool_result',
                toolCallId: item.toolCallId || item.content?.toolCallId,
                toolName: item.toolName || item.content?.toolName,
                result: item.result || item.content?.result
              },
              order: index
            };
          }
          
          // For tool calls, ensure proper structure
          if (type === 'tool_call') {
            return {
              type,
              content: {
                type: 'tool_call',
                toolCallId: item.toolCallId || item.content?.toolCallId,
                toolName: item.toolName || item.content?.toolName,
                args: item.args || item.content?.args
              },
              order: index
            };
          }
          
          // For text content
          return {
            type,
            content: item.text || item.content || item,
            order: index
          };
        });
      }
      // If parsed but not an array, treat as single text content
      return [{
        type: 'text',
        content: parsed,
        order: 0,
      }];
    } catch {
      // If not valid JSON, treat as plain text
      return [{
        type: 'text',
        content: content,
        order: 0,
      }];
    }
  }

  if (Array.isArray(content)) {
    return content.map((item, index) => {
      // Normalize type names
      const type = (item.type === 'tool-call' ? 'tool_call' : 
                   item.type === 'tool-result' ? 'tool_result' : 
                   item.type || 'text') as MessageContent['type'];
      
      // For tool results, ensure proper structure
      if (type === 'tool_result') {
        return {
          type,
          content: {
            type: 'tool_result',
            toolCallId: item.toolCallId || item.content?.toolCallId,
            toolName: item.toolName || item.content?.toolName,
            result: item.result || item.content?.result
          },
          order: index
        };
      }
      
      // For tool calls, ensure proper structure
      if (type === 'tool_call') {
        return {
          type,
          content: {
            type: 'tool_call',
            toolCallId: item.toolCallId || item.content?.toolCallId,
            toolName: item.toolName || item.content?.toolName,
            args: item.args || item.content?.args
          },
          order: index
        };
      }
      
      // For text content
      return {
        type,
        content: item.text || item.content || item,
        order: index
      };
    });
  }

  // If object or other type, wrap in array
  return [{
    type: 'text',
    content: content,
    order: 0,
  }];
}
