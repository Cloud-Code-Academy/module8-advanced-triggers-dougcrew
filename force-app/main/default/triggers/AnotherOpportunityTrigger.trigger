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


    /*
    notifyOwnersOpportunityDeleted:
    - Sends an email notification to the owner of the Opportunity when it gets deleted.
    - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    */
    // private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
    //     List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    //     for (Opportunity opp : opps){
    //         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //         String[] toAddresses = new String[] {[SELECT Id, Email FROM User WHERE Id = :opp.OwnerId].Email};
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

    /*
    assignPrimaryContact:
    - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    - Only updates the Opportunities that don't already have a primary contact.
    */
    // private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
    //     Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    //     for (Opportunity opp : oppNewMap.values()){            
    //         Contact primaryContact = [SELECT Id, AccountId FROM Contact WHERE Title = 'VP Sales' AND AccountId = :opp.AccountId LIMIT 1];
    //         if (opp.Primary_Contact__c == null){
    //             Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
    //             oppToUpdate.Primary_Contact__c = primaryContact.Id;
    //             oppMap.put(opp.Id, oppToUpdate);
    //         }
    //     }
    //     update oppMap.values();
    // }
}