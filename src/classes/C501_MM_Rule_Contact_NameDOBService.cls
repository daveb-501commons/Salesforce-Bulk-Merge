//
// Run Code from Developer Console
//  1) Debug -> Open Execute Anonymous Window
//  2) paste code
/*
    C501_MM_Rule_Contact_NameDOBService schedule = new C501_MM_Rule_Contact_NameDOBService();
    schedule.execute(null);
*/
//  3) click Execute
//
// Abort scheduled jobs
/*
    List<CronJobDetail> scheduledJobs = [SELECT Id FROM CronJobDetail WHERE Name like 'Contact_NameDOBService_%'];
    for (CronJobDetail scheduledJob :scheduledJobs) {
        Id jobId = [SELECT Id from CronTrigger WHERE CronJobDetailId = :scheduledJob.Id].Id;
        System.abortJob(jobId);
    }
*/
//
// Schedule Code from Developer Console
/*
    system.schedule('Contact_NameDOBService_0', '0 0 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_1', '0 1 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_2', '0 2 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_3', '0 3 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_4', '0 4 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_5', '0 5 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_6', '0 6 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_7', '0 7 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_8', '0 8 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_9', '0 9 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_10', '0 10 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_11', '0 11 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_12', '0 12 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_13', '0 13 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_14', '0 14 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_15', '0 15 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_16', '0 16 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_17', '0 17 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_18', '0 18 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_19', '0 19 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_20', '0 20 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_21', '0 21 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_22', '0 22 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_23', '0 23 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_24', '0 24 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_25', '0 25 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_26', '0 26 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_27', '0 27 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_28', '0 28 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_29', '0 29 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_30', '0 30 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_31', '0 31 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_32', '0 32 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_33', '0 33 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_34', '0 34 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_35', '0 35 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_36', '0 36 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_37', '0 37 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_38', '0 38 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_39', '0 39 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_40', '0 40 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_41', '0 41 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_42', '0 42 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_43', '0 43 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_44', '0 44 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_45', '0 45 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_46', '0 46 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_47', '0 47 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_48', '0 48 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_49', '0 49 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_50', '0 50 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_51', '0 51 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_52', '0 52 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_53', '0 53 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_54', '0 54 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_55', '0 55 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_56', '0 56 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_57', '0 57 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_58', '0 58 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
    system.schedule('Contact_NameDOBService_59', '0 59 * * * ?', new C501_MM_Rule_Contact_NameDOBService());
*/

global class C501_MM_Rule_Contact_NameDOBService implements Schedulable {

    global void execute(SchedulableContext SC) {

		//
		// Perform all SOQL Queries outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
		//

        // Get Merge Metric
        List<C501_Merge_Metric__c> mergeMetrics = [SELECT Id, Name, Confidence__c, Enable__c, Total_Merge__c, AutoMerge_Percentage__c FROM C501_Merge_Metric__c WHERE Name = 'Contact_NameDOBService'];
        if (mergeMetrics.isEmpty()) {
            mergeMetrics.add( new C501_Merge_Metric__c (
                Name = 'Contact_NameDOBService',
                Confidence__c = 100.0
            ));

            insert mergeMetrics;
        }

        if (!mergeMetrics[0].Enable__c) {
            return;
        }

		AggregateResult[] allAggregatedByContacts = [
            SELECT Count(AccountId), Birthdate, Gender__c, C501_FirstName_Initial__c, LastName, MAX(AccountId)MaxAccountId, MIN(AccountId)MinAccountId
            FROM Contact
            Where C501_FirstName_Initial__c <> '' and LastName <> '' and Birthdate <> null
            Group By C501_FirstName_Initial__c, LastName, Birthdate, Gender__c
            Having Count(AccountId) > 1
            Order By Count(AccountId) DESC];

		AggregateResult[] allAggregatedByServiceContacts = [
            SELECT Count(C501_Service_Household_Id__r.C501_Household__c), C501_Birthdate__c, C501_Gender__c, C501_FirstName_Initial__c, C501_Last_Name__c, C501_Service_Household_Id__r.C501_Start_Date__c, MAX(C501_Service_Household_Id__r.C501_Household__c)MaxAccountId, MIN(C501_Service_Household_Id__r.C501_Household__c)MinAccountId
            FROM C501_Service_Contact__c
            Where C501_FirstName_Initial__c <> ''
                and C501_Last_Name__c <> ''
                and C501_Birthdate__c <> null
                and C501_Service_Household_Id__r.C501_Start_Date__c <> null
                and (NOT C501_Service_Household_Id__r.C501_Program__c like '%Change Request%')
            Group By C501_FirstName_Initial__c, C501_Last_Name__c, C501_Birthdate__c, C501_Gender__c, C501_Service_Household_Id__r.C501_Start_Date__c
            Having Count(C501_Service_Household_Id__r.C501_Household__c) > 1
            Order By Count(C501_Service_Household_Id__r.C501_Household__c) DESC];

        String maxId;
        String minId;
        Set<String> accountsByService = new Set<String>();
        for (AggregateResult result : allAggregatedByServiceContacts)  {
            maxId = result.get('MaxAccountId').toString();
            minId = result.get('MinAccountId').toString();
            accountsByService.add(maxId);
            accountsByService.add(minId);
        }

        Map<String, C501_Account_Merge__c> mergeAccounts = new Map<String, C501_Account_Merge__c>();
        String uniqueId;
        for (AggregateResult result : allAggregatedByContacts)  {

            maxId = result.get('MaxAccountId').toString();
            minId = result.get('MinAccountId').toString();

            if (String.isEmpty(maxId) || String.isEmpty(minId) || maxId == minId) {
                continue;
            }

            if (accountsByService.contains(maxId) && accountsByService.contains(minId)) {

                system.debug('*****C501_MM_Rule_Contact_NameDOBService::execute ByContacts Found - maxId: ' + maxId
                    + ' minId: ' + minId + ' UniqueId: ' + uniqueId + ' Confidence: ' + mergeMetrics[0].Confidence__c
                    + 'MetricId: ' + mergeMetrics[0].Id);

                uniqueId = mergeMetrics[0].Name + String.valueOf(minId) + String.valueOf(maxId);

                mergeAccounts.put(uniqueId, new C501_Account_Merge__c(
                    Unique_Id__c = uniqueId,
                    Merge_Confidence__c = mergeMetrics[0].Confidence__c,
                    Account__c = minId,
                    Merge_Target_Account__c = maxId,
                    Merge_Metric__c = mergeMetrics[0].Id
                ));
            }
        }

        //
		// Perform all DML (Data Manipulation Language) calls (insert, update, merge, delete, restore) outside of loop to avoid Salesforce Governor Limits: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm
        //
		if (!mergeAccounts.isEmpty()) {
			Database.SaveResult[] insertResults = Database.insert(mergeAccounts.values(), false);

            // TBD - Look for anything other than Duplicate Id Error on Unique_Id__c which is expected
		}

        C501_MassMerge_SharedCode c501MassMerge_SharedCode = new C501_MassMerge_SharedCode();

        // Check to AutoMerge
        Integer mergeAutoMergeAttemptsRemaining = 5;            // SOQL Governor limit issue limit merge attempts to 5 because each Merge Attempt is currently 10 SOQL Queries
        if (mergeMetrics[0].AutoMerge_Percentage__c > 0.0) {

            Set<Id> accountsProcessed = new Set<Id>();
            for (C501_Account_Merge__c mergeCandidate : [
                SELECT Id, Account__c, Merge_Target_Account__c, Merge_Confidence__c
                FROM C501_Account_Merge__c
                WHERE Merge_Metric__r.Name = 'Contact_NameDOBService'
                LIMIT 200]) {

                    // Check whether account Id merge already attempted
                    if (accountsProcessed.contains(mergeCandidate.Account__c) || accountsProcessed.contains(mergeCandidate.Merge_Target_Account__c)) {
                        continue;
                    }

                    if (mergeAutoMergeAttemptsRemaining-- <= 0) {
                        break;
                    }

                    accountsProcessed.add(mergeCandidate.Account__c);
                    accountsProcessed.add(mergeCandidate.Merge_Target_Account__c);

                    system.debug('***** AutoMerge - Account__c: ' + mergeCandidate.Account__c + ' Merge_Target_Account__c: ' + mergeCandidate.Merge_Target_Account__c);

                    try {
                        c501MassMerge_SharedCode.AccountsMerge( new List<Account> {
                            new Account(
                                Id = mergeCandidate.Account__c,
                                C501_Merge_Action__c = 'Merge',
                                C501_Merge_Confidence__c = mergeCandidate.Merge_Confidence__c,
                                C501_Merge_Target__c = mergeCandidate.Merge_Target_Account__c,
                                C501_Merge_Metric_Name__c = mergeMetrics[0].Name,
                                C501_Merge_Account__c = mergeCandidate.Id
                            ),
                            new Account(
                                Id = mergeCandidate.Merge_Target_Account__c,
                                C501_Merge_Action__c = 'Merge',
                                C501_Merge_Confidence__c = mergeCandidate.Merge_Confidence__c,
                                C501_Merge_Target__c = mergeCandidate.Merge_Target_Account__c,
                                C501_Merge_Metric_Name__c = mergeMetrics[0].Name,
                                C501_Merge_Account__c = mergeCandidate.Id
                            )
                        } );
                    } catch (Exception e) {
                        // NoOp for now since Sandbox has partial data
                        system.debug('***** Account__c: ' + mergeCandidate.Account__c + ' Merge_Target_Account__c: ' + mergeCandidate.Merge_Target_Account__c);
                        system.debug('General Exception: ' + String.valueOf(e) + '\n\n' + e.getStackTraceString());
                    }
            }
        }
   }
}