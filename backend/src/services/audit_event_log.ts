import { db } from '../db';

/**
 * Unified audit pipeline.
 *
 * All audit-relevant writes (ambassador, aml, admin, etc.) must go through
 * this module so that retention, querying, and compliance fields stay
 * consistent across services.
 */

export type AuditActorType = 'user' | 'admin' | 'system' | 'service';

export type AuditAction =
  | 'ambassador.created'
  | 'ambassador.updated'
  | 'ambassador.deleted'
  | 'ambassador.status_changed'
  | 'aml.flagged'
  | 'aml.reviewed'
  | 'aml.cleared'
  | 'admin.action'
  | string;

export interface AuditEventInput {
  /** Who performed the action. */
  actor: string;
  /** Type of actor performing the action. */
  actorType?: AuditActorType;
  /** What happened. */
  action: AuditAction;
  /** The entity the action was performed against. */
  target: string;
  /** Optional target entity type (e.g. 'ambassador', 'aml_case'). */
  targetType?: string;
  /** Optional structured metadata for the event. */
  metadata?: Record<string, unknown>;
  /** Optional explicit timestamp; defaults to now. */
  timestamp?: Date;
}

export interface AuditEventRecord {
  id: string;
  actor: string;
  actorType: AuditActorType;
  action: AuditAction;
  target: string;
  targetType: string | null;
  metadata: Record<string, unknown> | null;
  timestamp: Date;
}

/**
 * Validate that all compliance-relevant fields are present before persisting.
 */
function assertComplianceFields(event: AuditEventInput): void {
  if (!event.actor || typeof event.actor !== 'string') {
    throw new Error('Audit event missing required field: actor');
  }
  if (!event.action || typeof event.action !== 'string') {
    throw new Error('Audit event missing required field: action');
  }
  if (!event.target || typeof event.target !== 'string') {
    throw new Error('Audit event missing required field: target');
  }
}

/**
 * Single entry point for writing audit events.
 *
 * Every service (ambassador, aml, admin) should call this instead of writing
 * audit records directly, guaranteeing consistent typing and compliance fields.
 */
export async function writeAuditEvent(event: AuditEventInput): Promise<AuditEventRecord> {
  assertComplianceFields(event);

  const record: AuditEventRecord = {
    id: generateAuditEventId(),
    actor: event.actor,
    actorType: event.actorType ?? 'user',
    action: event.action,
    target: event.target,
    targetType: event.targetType ?? null,
    metadata: event.metadata ?? null,
    timestamp: event.timestamp ?? new Date(),
  };

  await db('audit_event_log').insert({
    id: record.id,
    actor: record.actor,
    actor_type: record.actorType,
    action: record.action,
    target: record.target,
    target_type: record.targetType,
    metadata: record.metadata ? JSON.stringify(record.metadata) : null,
    timestamp: record.timestamp,
  });

  return record;
}

/**
 * Convenience helper for services that need to log an audit event without
 * awaiting the result (fire-and-forget), while still routing through the
 * unified pipeline.
 */
export function writeAuditEventAsync(event: AuditEventInput): void {
  void writeAuditEvent(event).catch((err) => {
    // eslint-disable-next-line no-console
    console.error('Failed to write audit event', { action: event.action, err });
  });
}

function generateAuditEventId(): string {
  return `audit_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}
