public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    public override void beforeUpdate() {
        OpportunityHelper.validatOppAmount(Trigger.new);
        OpportunityHelper.appendStageDescription((List<Opportunity>)Trigger.new, 
        (Map<Id, Opportunity>)Trigger.oldMap);
        OpportunityHelper.setPrimaryContactOnOppWithTitleOfCEO(Trigger.new);
    }
    
    public override void beforeInsert() {
        OpportunityHelper.newOppDefaultType(Trigger.new);
    }

    // public override void afterInsert() {
    //     OpportunityHelper.createNewTaskForOpportunity(Trigger.new);
    // }

    public override void beforeDelete() {
        OpportunityHelper.preventDeleteOnClosedOppBankingIndustry(Trigger.old);
        OpportunityHelper.preventDeleteOfClosedOpps(Trigger.old);
    }

    public override void afterDelete() {
        OpportunityHelper.notifyOwnersOpportunityDeleted(Trigger.old);
    }

    public override void afterUndelete() {
        OpportunityHelper.assignPrimaryContact((Map<Id,Opportunity>)Trigger.oldMap);
    }

}