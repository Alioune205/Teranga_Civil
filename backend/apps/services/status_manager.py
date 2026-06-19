"""
Workflow state transition validator.
"""
from django.core.exceptions import ValidationError

# Define allowed transitions: current_status -> list of allowed next_statuses
ALLOWED_STATUS_TRANSITIONS = {
    'draft': ['submitted'],
    'submitted': ['in_review', 'draft'],  # draft fallback if agent rejects/requests changes before review
    'in_review': ['approved', 'rejected', 'submitted'],
    'approved': ['completed'],
    'rejected': [],
    'completed': []
}


def validate_status_transition(current_status, next_status):
    """
    Validates if a transition from current_status to next_status is allowed.
    Raises ValidationError if the transition is illegal.
    """
    if current_status == next_status:
        return True

    allowed_next_states = ALLOWED_STATUS_TRANSITIONS.get(current_status, [])
    if next_status not in allowed_next_states:
        raise ValidationError(
            f"Transition de statut invalide. Impossible de passer de '{current_status}' à '{next_status}'."
        )
    return True


def is_transition_valid(current_status, next_status):
    """Boolean check for status transition validity."""
    try:
        validate_status_transition(current_status, next_status)
        return True
    except ValidationError:
        return False
