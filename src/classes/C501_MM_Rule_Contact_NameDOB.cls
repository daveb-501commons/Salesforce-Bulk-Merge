//
// Run Code from Developer Console
//  1) Debug -> Open Execute Anonymous Window
//  2) paste code
/*
      C501_MM_Rule_Contact_NameDOB schedule = new C501_MM_Rule_Contact_NameDOB();
      schedule.execute(null);
*/
//  3) click Execute
//

global class C501_MM_Rule_Contact_NameDOB implements Schedulable {

    global void execute(SchedulableContext SC) {

		//
		// Perform all SOQL Queries outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
		//

        // Get Merge Metric
        List<C501_Merge_Metric__c> mergeMetrics = [SELECT Id, Name, Confidence__c, Total_Merge__c FROM C501_Merge_Metric__c WHERE Name = 'Contact_NameDOB'];
        if (mergeMetrics.isEmpty()) {
            mergeMetrics.add( new C501_Merge_Metric__c (
                Name = 'Contact_NameDOB',
                Confidence__c = 90.0
            ));

            insert mergeMetrics;
        }

		AggregateResult[] allAggregatedAccounts = [
            SELECT Count(AccountId), Birthdate, C501_FirstName_Initial__c, LastName, MAX(AccountId)MaxAccountId, MIN(AccountId)MinAccountId
            FROM Contact
            Where C501_FirstName_Initial__c <> '' and LastName <> '' and Birthdate <> null
            Group By C501_FirstName_Initial__c, LastName, Birthdate
            Having Count(AccountId) > 1
            Order By Count(AccountId) DESC];

        Map<String, C501_Account_Merge__c> mergeAccounts = new Map<String, C501_Account_Merge__c>();
        String maxId;
        String minId;
        String uniqueId;
        for (AggregateResult result : allAggregatedAccounts)  {
            maxId = result.get('MaxAccountId').toString();
            minId = result.get('MinAccountId').toString();

            if (String.isEmpty(maxId) || String.isEmpty(minId) || maxId == minId) {
                continue;
            }

            uniqueId = mergeMetrics[0].Name + String.valueOf(minId) + String.valueOf(maxId);
            mergeAccounts.put(uniqueId, new C501_Account_Merge__c(
                Unique_Id__c = uniqueId,
                Merge_Confidence__c = mergeMetrics[0].Confidence__c,
                Account__c = minId,
                Merge_Target_Account__c = maxId,
                Merge_Metric__c = mergeMetrics[0].Id
            ));
        }

        //
		// Perform all DML (Data Manipulation Language) calls (insert, update, merge, delete, restore) outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
        //
		if (!mergeAccounts.isEmpty()) {
			Database.SaveResult[] insertResults = Database.insert(mergeAccounts.values(), false);

            // TBD - Look for anything other than Duplicate Id Error on Unique_Id__c which is expected
		}
   }
}