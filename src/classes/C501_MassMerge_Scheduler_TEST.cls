@istest
class C501_MassMerge_Scheduler_TEST {

    public static String CRON_EXP = '0 0 0 3 9 ? 2022';

    @testSetup static void setup() {

        list<Account> listAccounts = new list<Account>();   
        integer cAccounts = 5;     
        for (integer i = 0; i < cAccounts; i++) {
            Account account = new Account(
                
                // Request Information
                Name='Account Name'
            );
            listAccounts.add(account);
        }                      

        insert listAccounts;

        C501_Merge_Metric__c mergeMetric = new C501_Merge_Metric__c(
            Name = 'MergeMetric',
            Enable__c = true
        );

        insert mergeMetric;

        List<C501_Service_Household__c> listServiceHouseholds = new List<C501_Service_Household__c>();
        List<C501_Account_Merge__c> listAccountMerges = new List<C501_Account_Merge__c>();
        List<Contact> listContacts = new List<Contact>();
        List<C501_Service_Contact__c> listServiceContacts = new List<C501_Service_Contact__c>();
        for (Account account :listAccounts) {
            listServiceHouseholds.add( new C501_Service_Household__c(
                Name = 'Name ' + account.Id,
                C501_Service_Id__c = 'C501_Service_Id__c ' + account.Id,
                C501_Household__c = account.Id,
                C501_Program__c = 'Energy Assistance',
                C501_Start_Date__c = date.today()
            ));

            listAccountMerges.add( new C501_Account_Merge__c(
                Unique_Id__c = 'Merge ' + account.Id,
                Merge_Metric__c = mergeMetric.Id,
                Account__c = listAccounts[0].Id,
                Merge_Target_Account__c = account.Id,
                Merge_Confidence__c = 100,
                Merge_Action__c = 'Merge'
            ));

            listContacts.add( new Contact(
                LastName = 'Test',
                FirstName = 'Test',
                C501_FirstName_Initial__c = 'T',
                AccountId = account.Id,
                Birthdate = date.today()
            ));
        }

        insert listServiceHouseholds;
        insert listAccountMerges;
        insert listContacts;

        Integer serviceHouseholdIndex = 0;
        for (Contact contact :listContacts) {
            listServiceContacts.add( new C501_Service_Contact__c(
                C501_Last_Name__c = 'Test',
                C501_First_Name__c = 'Test',
                C501_FirstName_Initial__c = 'T',
                C501_Birthdate__c = date.today(),
                C501_Service_Household_Id__c = listServiceHouseholds[serviceHouseholdIndex].Id,
                C501_Service_Id__c = listServiceHouseholds[serviceHouseholdIndex].C501_Service_Id__c,
                C501_contact_Id__c = contact.Id
            ));
            serviceHouseholdIndex++;
        }
    }

    static testmethod void C501_MassMerge_Scheduler_TEST_Schedule() {

        Test.startTest();

        Account account1 = new Account(
            Name = 'Account1',
            BillingStreet = '123 Street',
            Phone = '(123) 456-7890'
        );
        insert account1;

        Account account2 = new Account(
            Name = 'Account2',
            BillingStreet = '123 Street',
            Phone = '(123) 456-7890'
        );
        insert account2;

        C501_Merge_Metric__c mergeMetric = new C501_Merge_Metric__c(
            Name = 'MergeMetric',
            Enable__c = true
        );

        insert mergeMetric;

        C501_Account_Merge__c accountMerge = new C501_Account_Merge__c(
                Unique_Id__c = 'Name ' + account1.Id,
                Merge_Metric__c = mergeMetric.Id,
                Account__c = account1.Id,
                Merge_Target_Account__c = account2.Id,
                Merge_Confidence__c = 100.0,
                Merge_Action__c = 'Merge');

        insert accountMerge;

        // Schedule the test job
        String jobId = System.schedule('testBasicScheduledApex',
        C501_MassMerge_Scheduler_TEST.CRON_EXP, 
            new C501_MM_Rule_Contact_NameDOB());

        // Get the information FROM the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
            NextFireTime
            FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(C501_MassMerge_Scheduler_TEST.CRON_EXP, 
            ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2022-09-03 00:00:00', 
            String.valueOf(ct.NextFireTime));

        System.assert(
            100.0 == [SELECT Id, Merge_Confidence__c FROM C501_Account_Merge__c WHERE Unique_Id__c = :accountMerge.Unique_Id__c LIMIT 1].Merge_Confidence__c);

        Test.stopTest();

        //System.assert(
        //    100.0 == [SELECT Id, Merge_Confidence__c FROM C501_Account_Merge__c].Merge_Confidence__c);
   }

    static testmethod void C501_MM_Rule_Contact_NameDOB_TEST() {

        C501_MM_Rule_Contact_NameDOB scheduleNameDOB = new C501_MM_Rule_Contact_NameDOB();
        scheduleNameDOB.execute(null);
   }   

    static testmethod void C501_MM_Rule_Contact_NameDOBService_TEST() {

        C501_MM_Rule_Contact_NameDOBService scheduleNameDOBService = new C501_MM_Rule_Contact_NameDOBService();
        scheduleNameDOBService.execute(null);
   }   
}