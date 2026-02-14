import { LightningElement,api,wire,track } from 'lwc';
import getSalesOrderRec from '@salesforce/apex/SalesOrderService.getSalesOrderRec';  
import  getmdtCategory from '@salesforce/apex/SPAChecklistController.getmdtCategory';  
import saveSPA from '@salesforce/apex/SPAChecklistController.saveSPA'; 
import  DataToDisplay from '@salesforce/apex/SPAChecklistController.DataToDisplay'; 
import {NavigationMixin} from 'lightning/navigation'; 


import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 

                     
                     
export default class SPAChecklist extends NavigationMixin(LightningElement){
                     
  @track recId;
  @track showData;
  @track showCategory;
  showSuppPersonDocs=[];
  @track Admin;
  @track CM;
  @track Notes;
  @track showSuppDocs;
  @track allvalues={};
   editedValues=[];  
   @track noSalesOrder=false;
   @track showtable=false;

  connectedCallback(){
    this.recId=  new URL(window.location.href).searchParams.get("c__rId");

                     
                        
      getSalesOrderRec({
                           
         SalesOrderId:this.recId
                          
          }).then(result=>{ 
             if (result) {
            
              this.showData = result;
              this.showtable=true;
         

              if(this.showData.length==0){
                  this.noSalesOrder=true;
                  this.showtable=false;
              }
                
            }                  
           }).catch(error => {  
                console.log('error ', error);  
      });  
                     
      getmdtCategory({ }).then(result=>{ 
        if (result) {
          console.log('getmdtCategory');
          console.log(result);
          this.showCategory = result;
           
        }
         }).catch(error => {  
           console.log('error ', error);  
       });  
                                 
       DataToDisplay({
        salesOrderId:this.recId
      }).then(result=>{ 
        if (result) {
          console.log('result');
          console.log(result);
        var count=0;
        this.showAllDocs = result;
    
           
        this.showAllDocs.forEach(x=>{
        x.Idx= count;
        if(this.allvalues.hasOwnProperty(x.ChecklistCategory__c)){
          var temp=this.allvalues[x.ChecklistCategory__c];
          x.SrNo=temp.length+1;
        
          temp.push(x);
          this.allvalues[x.ChecklistCategory__c]=temp;
          }else{
            var temp=[];
             x.SrNo=1;
            temp.push(x);
            this.allvalues[x.ChecklistCategory__c]=temp;
          
          }count++;
       
        })
        console.log('---');
        console.log(JSON.stringify( this.allvalues));
          
        }
      }).catch(error => {  
           console.log('error ', error);  
       }); 
  }
                     
                 
                     

  handleChange(event){                  
  var index= event.detail.index;
  var apiname= event.detail.apiname;
  var targetval=event.detail.value;
  this.showAllDocs[index][apiname]=targetval;
  this.showAllDocs[index].isEdited=true;
 
  }
                  
                  
  saveRecord(event){
  
   var editlist=[];
   this.showAllDocs.forEach(X=>{
       if(X.isEdited && X.isEdited==true){
        editlist.push(X);
       }
   })
    saveSPA({  
                        
      spaRecord: editlist,
      salId: this.recId
                        
       }).then(spaId => { 
       
       if (spaId) {  
         
           this.dispatchEvent(  
             new ShowToastEvent({  
              title: 'Success',  
              variant: 'success',  
                message: 'SPA Record Successfully Updated/Created',  
           }),  
       ); 
  
      
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'SalesOrder__c', 
                actionName: 'view'
            }
        });
    
         }  
        }).catch(error => {  
              console.log('error ', error);  
       });  
   }                    
                     
                            
                      
                     
                     
}