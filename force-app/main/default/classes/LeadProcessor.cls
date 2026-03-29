public with sharing class LeadProcessor implements Database.Batchable<SObject>{
    public  Database.QueryLocator start(Database.BatchableContext ctx){
        return LeadProcessorSelector.getQueryLocator();
    }

   public  void execute (Database.BatchableContext ctx, List<Lead> leads){
       
        if(leads == null || leads.isEmpty())
        return;

        for(Lead lead: leads){
            lead.LeadSource = LeadConstants.LEAD_SOURCE_DREAMFORCE;
        }

        Database.update(leads,true);
           

        }
    

    public void  finish(Database.BatchableContext ctx){
     //Some final task
    }

}


