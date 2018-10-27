//
// Run Code from Developer Console
//  1) Debug -> Open Execute Anonymous Window
//  2) paste code
//      C501_MassMerge_Scheduler schedule = new C501_MassMerge_Scheduler();
//      schedule.execute(null);
//  3) click Execute
//

global class C501_MassMerge_Scheduler implements Schedulable {

    global void execute(SchedulableContext SC) {

		//
		// Perform all SOQL Queries outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
		//
		AggregateResult[] allAggregatedAccounts = [
            SELECT Count(Id), BillingStreet, Phone, MAX(Id), MIN(Id)
            FROM Account
            Where BillingStreet <> '' and Phone <> '' and Phone <> '()'
            Group By BillingStreet, Phone
            Having Count(Id) > 1
            Order By Count(Id) DESC
            LIMIT 10];

        Map<String, C501_Account_Merge__c> mergeAccounts = new Map<String, C501_Account_Merge__c>();
        String maxId;
        String minId;
        String uniqueId;
        for (AggregateResult result : allAggregatedAccounts)  {
            maxId = result.get('expr1').toString();
            minId = result.get('expr2').toString();
            uniqueId = String.valueOf(maxId) + String.valueOf(maxId);
            mergeAccounts.put(uniqueId, new C501_Account_Merge__c(
                //Unique_Id__c = uniqueId,
                Merge_Confidence__c = 100.0,
                Account__c = minId,
                Merge_Target_Account__c = maxId
            ));
        }

        //
		// Perform all DML (Data Manipulation Language) calls (insert, update, merge, delete, restore) outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
        //
		if (!mergeAccounts.isEmpty()) {
			insert mergeAccounts.values();
		}
   }
}