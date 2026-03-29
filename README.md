# LeadProcessor — Batch Apex

Solução de batch para atualização em massa do campo `LeadSource` de registros `Lead` no Salesforce, desenvolvida com foco em boas práticas de código corporativo.

---

## Visão Geral

Este projeto implementa um Batch Apex que localiza todos os `Lead` cujo `LeadSource` não é `Dreamforce` e atualiza esse campo em massa. O código vai além do mínimo necessário para demonstrar padrões de arquitetura recomendados para ambientes de produção.

---

## Estrutura do Projeto

```
force-app/
├── LeadConstants.cls          # Classe de constantes centralizadas
├── LeadProcessorSelector.cls  # Classe Selector — responsável pela query
├── LeadProcessor.cls          # Batch Apex principal
└── LeadProcessorTest.cls      # Classe de testes
```

---

## Classes

### `LeadConstants`
Centraliza os valores constantes utilizados em todo o projeto. Elimina strings mágicas e garante que qualquer alteração de valor seja feita em um único lugar.

```apex
public class LeadConstants {
    public static final String LEAD_SOURCE_DREAMFORCE = 'Dreamforce';
}
```

---

### `LeadProcessorSelector`
Responsável pela query SOQL. Segue o padrão Selector para desacoplar a responsabilidade de busca de dados da lógica de negócio.

```apex
public with sharing class LeadProcessorSelector {
    public static Database.QueryLocator getQueryLocator(){
        return Database.getQueryLocator([
            SELECT Id FROM Lead
            WHERE LeadSource != :LeadConstants.LEAD_SOURCE_DREAMFORCE
            AND LeadSource != null
            WITH USER_MODE
        ]);
    }
}
```

**Destaques:**
- SOQL estático — validado em tempo de compilação
- `WITH USER_MODE` — respeita Field-Level Security e Object-Level Security
- `with sharing` — respeita Sharing Rules, OWD e Role Hierarchy

---

### `LeadProcessor`
Classe principal do batch. Delega a query para a Selector e aplica a atualização nos registros.

```apex
public with sharing class LeadProcessor implements Database.Batchable<SObject>{
    public Database.QueryLocator start(Database.BatchableContext ctx){
        return LeadProcessorSelector.getQueryLocator();
    }
    public void execute(Database.BatchableContext ctx, List<Lead> leads){
        if(leads == null || leads.isEmpty()) return;
        for(Lead lead: leads){
            lead.LeadSource = LeadConstants.LEAD_SOURCE_DREAMFORCE;
        }
        Database.update(leads, true);
    }
    public void finish(Database.BatchableContext ctx){
        // Lógica de finalização (ex: envio de notificação, log, etc.)
    }
}
```

---

### `LeadProcessorTest`
Cobertura de testes com 200 registros, validando o comportamento do batch de ponta a ponta.

```apex
@IsTest
public with sharing class LeadProcessorTest {
    @TestSetup
    static void makeData(){
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i < 200; i++){
            leads.add(new Lead(LastName = 'test' + i, Company = 'Test' + i));
        }
        Database.insert(leads, true);
    }
    @IsTest
    static void testInsertedLeads(){
        Test.startTest();
        LeadProcessor leadProcessor = new LeadProcessor();
        Id jobId = Database.executeBatch(leadProcessor, 200);
        Test.stopTest();
        System.assertEquals(200, [SELECT COUNT() FROM Lead
            WHERE LeadSource = :LeadConstants.LEAD_SOURCE_DREAMFORCE]);
        System.assertNotEquals(null, jobId);
        System.assertEquals(0, [SELECT COUNT() FROM Lead
            WHERE LeadSource != :LeadConstants.LEAD_SOURCE_DREAMFORCE
            AND LeadSource != null]);
    }
}
```

---

## Boas Práticas Aplicadas

| Prática | Descrição |
|---|---|
| **Classe de Constantes** | Valores centralizados em `LeadConstants` — sem strings mágicas espalhadas pelo código |
| **Padrão Selector** | Query isolada em `LeadProcessorSelector` — desacoplada, reutilizável e de fácil manutenção |
| **SOQL Estático** | Validação em compile time e suporte correto a bind variables |
| **`with sharing`** | Respeita Sharing Rules, OWD e Role Hierarchy |
| **`WITH USER_MODE`** | Respeita Field-Level Security (FLS) e Object-Level Security na query |
| **DML sem try/catch manual** | `Database.update(leads, true)` — a plataforma garante rollback automático e logs completos |
| **Guard clause no execute** | Verificação de lista nula ou vazia antes de processar |

---

## Como Executar

Via Developer Console ou VS Code com Salesforce CLI:

```bash
# Executar o batch via Anonymous Apex
LeadProcessor lp = new LeadProcessor();
Database.executeBatch(lp, 200);
```

---

## Requisitos

- Salesforce API v55.0+
- Permissão de leitura e edição no objeto `Lead`
- Field-Level Security configurada para o campo `LeadSource`
