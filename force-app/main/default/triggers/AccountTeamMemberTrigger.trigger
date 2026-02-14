trigger AccountTeamMemberTrigger on AccountTeamMember (after insert, after update, before delete) {
    new AccountTeamMemberTriggerHandler().run('AccountTeamMember');
}