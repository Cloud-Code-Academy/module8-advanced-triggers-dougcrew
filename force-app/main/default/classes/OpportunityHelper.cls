public with sharing class OpportunityHelper {

        public static void validateAmount(List<Opportunity> oppList){
            for(Opportunity opp : oppList){
                if(opp.Amount < 5000){
                    opp.addError('Opportunity amount must be greater than 5000');
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

        public static void assignPrimaryContact(Map<Id,Opportunity> newOppMap) {        
                Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
                Set<Id> accIds = new Set<Id>();
                for(Opportunity opp : newOppMap.values()){
                    accIds.add(opp.AccountId);
                }

                Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, (SELECT Id FROM Contacts WHERE Title = 'VP Sales' LIMIT 1) FROM Account WHERE Id IN :accIds]);

                List<Opportunity> oppsToUpdate = new List<Opportunity>();
                for (Opportunity opp : newOppMap.values()){            
                   
                    if (opp.Primary_Contact__c == null){
                        Account acc = accMap.get(opp.AccountId);

                        if(acc != null && !acc.Contacts.isEmpty()){
                            Opportunity oppToUpdate = new Opportunity(
                                Id = opp.Id,
                                Primary_Contact__c = acc.Contacts[0].Id
                            );
                            oppsToUpdate.add(oppToUpdate);
                        }
                        
                    }
                }
              if(!oppsToUpdate.isEmpty()){
                update oppsToUpdate;
              }
            }
   
}
    