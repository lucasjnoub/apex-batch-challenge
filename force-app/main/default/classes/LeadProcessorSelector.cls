public with sharing class LeadProcessorSelector {
   
    public static Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator([
            SELECT ID FROM LEAD WHERE LeadSource != :LeadConstants.LEAD_SOURCE_DREAMFORCE OR LeadSource = null
        ]);
    }

}