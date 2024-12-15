public with sharing class OpportunityTriggerHandler extends Triggerhandler {


    public OpportunityTriggerHandler() {
                this.setMaxLoopCount(1);
            }

        public static void validateAmount(List<Opportunity> oppList){
            for(Opportunity opp : oppList){
                if(opp.Amount < 5000){
                    opp.addError('Opportunity amount must be greater than 5000');
                }
            }
        }
        public static void validateDeletion(List<Opportunity> oldOpportunities){
            Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Industry FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id IN :oldOpportunities)]);
            for(Opportunity opp : oldOpportunities){
                if(opp.StageName == 'Closed Won'){
                    if(accounts.get(opp.AccountId).Industry == 'Banking'){
                        opp.addError('Cannot delete a closed won opportunity for a banking account');
                    }
                }
            }
        }
        // public static void validateCloseOpportunity (List<Opportunity> oppsToDelete) {
        //     for (Opportunity oldOpp : oppsToDelete){
        //         if (oldOpp.IsClosed){
        //             oldOpp.addError('Cannot delete closed opportunity');
        //         }
        //     }
        // }
    
            
        public static void setPrimaryContact(List<Opportunity> updatedOpps) {
            Set<Id> accountIds = new Set<Id>();
            for(Opportunity opp : updatedOpps){
                accountIds.add(opp.AccountId);
            }
            
            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
    
            for (Contact cont : contacts.values()) {
                if (!accountIdToContact.containsKey(cont.AccountId)) {
                    accountIdToContact.put(cont.AccountId, cont);
                }
            }
    
            for(Opportunity opp : updatedOpps){
                if(opp.Primary_Contact__c == null){
                    if (accountIdToContact.containsKey(opp.AccountId)){
                        opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                    }
                }
            }
        }
    
        public static void setType(List<Opportunity> opps) {
            List<Opportunity> oppsToInsert = new List<Opportunity>();
            for (Opportunity opp : opps) {
                if (opp.Type == null){
                    opp.Type = 'New Customer';
                    oppsToInsert.add(opp);
                } 
            } insert oppsToInsert;
        }
    
        public static void createTaskForPrimaryContact (List<Opportunity> newOpps) {
            List<Task> tasksToCreate = new List<Task>();
            for (Opportunity opp : newOpps){
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                tsk.WhoId = opp.Primary_Contact__c;
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasksToCreate.add(tsk);
            } insert tasksToCreate;
        }
    
        public static void updateDescriptionFromStage(List<Opportunity> newOpps, Map<Id, Opportunity> oldOppsMap){ 

            String timestamp = DateTime.now().format();

            for ( Opportunity newOpp : newOpps) {
                Opportunity oldOpp = oldOppsMap.get(newOpp.Id);
                if (oldOpp != null && oldOpp.StageName != newOpp.StageName) {
                    newOpp.Description += '\n Stage Change:' + newOpp.StageName + ':' + timestamp;
                } else { 
                newOpp.Description = newOpp.Description;
                }
            }   
        }
    
        public static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Map<Id, Opportunity> oppEmailMap = new Map<Id, Opportunity>();
    
            Set<Id> ownerIds = new Set<Id>();
            for(Opportunity opp : opps) {
                oppEmailMap.put(opp.Id, opp);
                ownerIds.add(opp.OwnerId);
            }
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :ownerIds]);
            for (Opportunity opp : opps){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String [] toAddresses = new String[] {userMap.get(opp.OwnerId).Email};
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
    
        public static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
            for (Opportunity opp : oppNewMap.values()){            
                Contact primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId = :opp.AccountId LIMIT 1];
                if (opp.Primary_Contact__c == null){
                    Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                    oppToUpdate.Primary_Contact__c = primaryContact.Id;
                    oppMap.put(opp.Id, oppToUpdate);
                }
            }
            update oppMap.values();
        }
}