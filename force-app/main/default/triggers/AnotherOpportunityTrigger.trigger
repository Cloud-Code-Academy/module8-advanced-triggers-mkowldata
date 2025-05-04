/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance
Avoid DML inside for loop - 1 instance
Bulkify Your Code - 1 instance
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            // Set default Type for new Opportunities
            for(Opportunity opp : Trigger.new) {
            if (opp.Type == null){
                opp.Type = 'New Customer';
                }    
            }    
        } else if (Trigger.isDelete){
            // Prevent deletion of closed Opportunities
            for (Opportunity oldOpp : Trigger.old) {
                if (oldOpp.IsClosed){
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
        } else if (Trigger.isUpdate){
            // Append Stage changes in Opportunity Description
            for (Opportunity opp : Trigger.new) {
                Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
                if (opp.StageName != null && opp.StageName != oldOpp.StageName) {
                        opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                    }
                }                
        }
    }
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            // Create a new Task for newly inserted Opportunities
            List<Task> tasks = new List<Task>();
            for (Opportunity opp : Trigger.new) {
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3); 
                tasks.add(tsk);
            }
            insert tasks;
        
        // Send email notifications when an Opportunity is deleted 
        } else if (Trigger.isDelete){
            OpportunityHelper.notifyOwnersOpportunityDeleted(Trigger.old);
        
        // Assign the primary contact to undeleted Opportunities
        } else if (Trigger.isUndelete){
            OpportunityHelper.assignPrimaryContact(Trigger.newMap);
        }
    }
}

    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */

    // private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
    //     List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    //     Set<Id> ownerIds = new Set<Id>();
    //     for(Opportunity opp : opps) {
    //         ownerIds.add(opp.OwnerId);
    //     }
    //     List<User> userList = [SELECT Id, Email FROM User WHERE Id IN :ownerIds];
    //     Map<Id, User> userMap = new Map<Id, User>(); 
    //     //put query of user list into map
    //     for(User users : userList) {
    //         userMap.put(users.Id, users);
    //     }
    //     for (Opportunity opp : opps){
    //         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //         String ownerEmail = userMap.get(opp.OwnerId).Email;
    //         List<String> toAddresses = new List<String> {ownerEmail};
    //         mail.setToAddresses(toAddresses);
    //         mail.setSubject('Opportunity Deleted : ' + opp.Name);
    //         mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
    //         mails.add(mail);
    //     }        
        
    //     try {
    //         Messaging.sendEmail(mails);
    //     } catch (Exception e){
    //         System.debug('Exception: ' + e.getMessage());
    //     }
    // }


    // /*
    // assignPrimaryContact:
    // - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    // - Only updates the Opportunities that don't already have a primary contact.
    // // */
    // private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {  
    // //create set to capture Ids for each opp //loop through oppNewMap to pull accountId to add to set      
        
    //     Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    //     Set<Id> oppAccountIds = new Set<Id>();
    //     for (Opportunity opp : oppNewMap.values()) {
    //         oppAccountIds.add(opp.AccountId);
    //     }

    //     //create list of primaryContacts outside of for loop //loop trhough primaryContact list to get accountId and contact to add to Map
    //     List<Contact> primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId IN :oppAccountIds];
    //     Map<Id, Contact> accountIdToContactMap = new Map<Id, Contact>(); //create map to capture accountId to contact
    //     for (Contact cont : primaryContact) {
    //         if(!accountIdToContactMap.containsKey(cont.AccountId)) {
    //             accountIdToContactMap.put(cont.AccountId, cont);
    //         }
    //     }
        
    //     for (Opportunity opp : oppNewMap.values()){            
    //         if (opp.Primary_Contact__c == null){
    //             if(accountIdToContactMap.containsKey(opp.AccountId)) {
    //             Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
    //             Contact primaryCont = accountidToContactMap.get(opp.AccountId);
    //             oppToUpdate.Primary_Contact__c = primaryCont.Id;
    //             oppMap.put(opp.Id, oppToUpdate);
    //             }
    //         }
    //     }
    //     update oppMap.values();

