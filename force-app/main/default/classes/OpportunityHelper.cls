public with sharing class OpportunityHelper {
    
    //When an opportunity is updated validate that the amount is greater than 5000 (trigger isBefore isUpdate).
    public static void validatOppAmount(List<Opportunity> newOpps) {
        for(Opportunity opp : newOpps){
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
    }
    
    //When an opportunity is deleted prevent the deletion of a closed won opportunity if the account industry is 'Banking' (trigger isDelete).
    public static void preventDeleteOnClosedOppBankingIndustry(List<Opportunity> deleteClosedOppsBanking) {
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :Trigger.old)]);
        for(Opportunity opp : deleteClosedOppsBanking){
            if(opp.StageName == 'Closed Won'){
                if(accounts.get(opp.AccountId).Industry == 'Banking'){
                    opp.addError('Cannot delete a closed won opportunity for a banking account');
                }
            }
        }
    }

    // Prevent deletion of closed Opportunities (trigger isDelete)
    public static void preventDeleteOfClosedOpps(List<Opportunity> deleteClosedOpps) {
        for (Opportunity oldOpp : deleteClosedOpps) {
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }
        }
    }

    // Append Stage changes in Opportunity Description (trigger isBefore isUpdate)
    public static void appendStageDescription(List<Opportunity> updateStageDescription, Map<Id, Opportunity> oldOpportunityMap){
        for (Opportunity opp : updateStageDescription) {
            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
            if (opp.StageName != null && opp.StageName != oldOpp.StageName) {
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
            }
        }   
    }
    
    //When an opportunity is updated set the primary contact on the opportunity to the contact with the title of 'CEO' (trigger isBefore isUpdate).
    public static void setPrimaryContactOnOppWithTitleOfCEO(list<Opportunity> oppsToUpdateContact) {
        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : oppsToUpdateContact){
            accountIds.add(opp.AccountId);
        }
        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();

        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        for(Opportunity opp : oppsToUpdateContact) {
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }

    // Set default Type for new Opportunities (trigger isBefore isInsert)
    public static void newOppDefaultType (List<Opportunity> newOppDefaultType) {
        for(Opportunity opp : newOppDefaultType) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }    
        }  
    }

    // Create a new Task for newly inserted Opportunities (trigger isAfter isInsert)
    public static void createNewTaskForOpportunity(List<Opportunity> createTasksForOpps){
        List<Task> tasks = new List<Task>();
            for (Opportunity opp : createTasksForOpps) {
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3); 
            tasks.add(tsk);
        }
        insert tasks;
    }

        /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */

    public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Set<Id> ownerIds = new Set<Id>();
        for(Opportunity opp : opps) {
            ownerIds.add(opp.OwnerId);
        }
        List<User> userList = [SELECT Id, Email FROM User WHERE Id IN :ownerIds];
        Map<Id, User> userMap = new Map<Id, User>(); 
        //put query of user list into map
        for(User users : userList) {
            userMap.put(users.Id, users);
        }
        for (Opportunity opp : opps){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String ownerEmail = userMap.get(opp.OwnerId).Email;
            List<String> toAddresses = new List<String> {ownerEmail};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {  
        //create set to capture Ids for each opp //loop through oppNewMap to pull accountId to add to set      
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> oppAccountIds = new Set<Id>();
        for (Opportunity opp : oppNewMap.values()) {
            oppAccountIds.add(opp.AccountId);
        }

        //create list of primaryContacts outside of for loop //loop trhough primaryContact list to get accountId and contact to add to Map
        List<Contact> primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :oppAccountIds];
        Map<Id, Contact> accountIdToContactMap = new Map<Id, Contact>(); //create map to capture accountId to contact
        for (Contact cont : primaryContact) {
            if(!accountIdToContactMap.containsKey(cont.AccountId)) {
                accountIdToContactMap.put(cont.AccountId, cont);
            }
        }
        
        for (Opportunity opp : oppNewMap.values()){            
            if (opp.Primary_Contact__c == null){
                if(accountIdToContactMap.containsKey(opp.AccountId)) {
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                Contact primaryCont = accountidToContactMap.get(opp.AccountId);
                oppToUpdate.Primary_Contact__c = primaryCont.Id;
                oppMap.put(opp.Id, oppToUpdate);
                }
            }
        }
        update oppMap.values();
    }
}