public with sharing class OpportunityTriggerHandler extends Triggerhandler {

    private List<Opportunity> newOppList;
    private List<Opportunity> oldOppList;
    private Map<Id, Opportunity> newOppMap;
    private Map<Id, Opportunity> oldOppMap;

    public OpportunityTriggerHandler(){
        this.newOppList = (List<Opportunity>) Trigger.new;
        this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldOppList = (List<Opportunity>) Trigger.old;
        this.OldOppMap = (Map<Id, Opportunity>) Trigger.oldMap;
        // public static Boolean hasRun = false;

        // Boolean stopTrigger = Trigger_Setting__mdt.getInstance('OpportunityBestPracticeTrigger')?.Disable_Trigger__c;

        //     if (stopTrigger == true || hasRun == true) {
        //         TriggerHandler.bypass('OpportunityTriggerHandler');
        //     } 
        //     hasRun = true;

            this.setMaxLoopCount(1);
        }

        public override void beforeInsert() {
            for ( Opportunity opp : this.newOppList)
                if (opp.Type == null){
                    opp.Type = 'New Customer';
            } 

            
        }

        public override void beforeUpdate() {
            for(Opportunity opp : this.newOppList){
                if(opp.Amount < 5000){
                    opp.addError('Opportunity amount must be greater than 5000');
                }
            }


            Set<Id> accountIds = new Set<Id>();
            for(Opportunity opp : this.newOppList){
                accountIds.add(opp.AccountId);
            }
            Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO' ORDER BY FirstName ASC]);
            Map<Id, Contact> accountIdToContact = new Map<Id, Contact>(); 
            for (Contact cont : contacts.values()) {
                if (!accountIdToContact.containsKey(cont.AccountId)) {
                    accountIdToContact.put(cont.AccountId, cont);
                }
            }
            for(Opportunity opp : newOppList){
                if(opp.Primary_Contact__c == null){
                    if (accountIdToContact.containsKey(opp.AccountId)){
                        opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                    }
                }
            }
          
        }

        public override void beforeDelete() {
            for (Opportunity oldOpp : this.oldOppList){
                if (oldOpp.IsClosed){
                    oldOpp.addError('Cannot delete closed opportunity');
                }
            }
          
        }

        public override void afterInsert() {
            List<Task> tasksToCreate = new List<Task>();

            for (Opportunity opp : this.newOppList){               
                Task tsk = new Task();
                tsk.Subject = 'Call Primary Contact';
                tsk.WhatId = opp.Id;
                if(opp.Primary_Contact__c != null){
                tsk.WhoId = opp.Primary_Contact__c;
                }
                tsk.OwnerId = opp.OwnerId;
                tsk.ActivityDate = Date.today().addDays(3);
                tasksToCreate.add(tsk);
                }  
            
            if (!tasksToCreate.isEmpty()) {
                try {
                    insert tasksToCreate;
                } catch (DmlException e) {
                    for (Opportunity opp : this.newOpplist) {
                        opp.addError('Unable to create task: ' + e.getMessage());
                    }
                }
            }
            
        }

        public override void afterUpdate() {
            String timestamp = DateTime.now().format();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for ( Opportunity newOpp : this.newOppList) {
                Opportunity oldOpp = oldOppMap.get(newOpp.Id);
                if (oldOpp != null && oldOpp.StageName != newOpp.StageName) {
                    
                    Opportunity oppToUpdate = new Opportunity(
                        Id = newOpp.Id,
                        Description = newOpp.Description + '\n Stage Change:' + newOpp.StageName + ':' + timestamp
                        );
                        oppsToUpdate.add(oppToUpdate);
                }
      
            } 
            if (!oppsToupdate.isEmpty()) {
                update oppsToUpdate;
            }
        }

        public override void afterDelete() {
            OpportunityHelper.notifyOwnersOpportunityDeleted(this.oldOppList);
          
        }

        public override void afterUndelete() {
            OpportunityHelper.assignPrimaryContact(this.newOppMap);
              
        }
      
}