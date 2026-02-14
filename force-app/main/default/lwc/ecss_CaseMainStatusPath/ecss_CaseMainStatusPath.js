import { LightningElement, api, wire, track } from "lwc";
import { getPicklistValues, getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord } from "lightning/uiRecordApi";
import STATUS_FIELD from "@salesforce/schema/Case.Status";
import SUB_STATUS_FIELD from "@salesforce/schema/Case.Status";
import RESOLVED from "@salesforce/schema/Case.Resolved_Status__c";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import { subscribe, unsubscribe, onError } from "lightning/empApi";

const FIELDS = [
  "Case.Id",
  "Case.Status",
  "Case.RecordTypeId",
  "Case.Sub_Status__c",
  "Case.Previous_Status__c",
  "Case.Previous_SubStatus__c"
];

export default class ECSS_MaintenanceCaseStatusNoButton extends LightningElement {
  subscription = {};
  channelName = "/event/RefreshComp__e";
  showSpinner = false;
  @api recordId;
  @track record = {};
  @track picklistResolvedValues = {};
  @track picklistStatusFieldValues = {};
  @track picklistSubstatusValues = {};
  @track RecordTypeIdval;
  @track CaseRecord;
  @track error;
  @track selectedValue;
  @track selectedSubValue;
  @track tempVariable;
  @track fieldType = "Status";

  // Variable to hold wire result
  wiredSubstatusResult;

  connectedCallback() {
    // console.log('recordId---'+this.recordId);
    this.registerErrorListener();
    this.registerEmpListener();
  }

  registerErrorListener() {
    onError((error) => {
      //console.error('Received error from EMP API: ', JSON.stringify(error) );
    });
  }

  fatchCaseRecord() {
    // getCaseRecord().then({caseId : this.recordId})
  }

  registerEmpListener() {
    const messageCallback = (response) => {
      if (response) {
        console.log("registerEmpListener" + JSON.stringify(response));
        const CaseStatusValue = response.data.payload.message__c.split("-");

        if (CaseStatusValue.length > 0 && CaseStatusValue[0] == "status") {
          console.log("Status Section Called" + JSON.stringify(response));
          // console.log('Current Status Value '+CaseStatusValue[1]);
          // console.log('Current Status record Value '+CaseStatusValue[2]);
          // console.log('PlateFrom recordId '+CaseStatusValue[3]);
          // const self =this;
          this.selectedValue = CaseStatusValue[1];
          this.RecordTypeIdval = CaseStatusValue[2];
          // this.recordId = CaseStatusValue[3];
          // self.refreshWireData();
          // refreshApex(this.tempVariable);
          //   window.location.reload();
        } else if (
          CaseStatusValue.length > 0 &&
          CaseStatusValue[0] == "Substatus"
        ) {
          console.log("Current sub Status Value " + CaseStatusValue[1].value);
          this.selectedSubValue = CaseStatusValue[1];
        }
      }
      // console.log('Substatus'+ response.data.payload.message__c);
      //if(response.data.payload.message__c == 'Substatus') {
      //  this.selectedValue = 'New';
      // }
    };

    subscribe(this.channelName, -1, messageCallback).then((response) => {
      this.subscription = response;
    });
    //
  }

  // refreshWireData()
  // {
  //     console.log('this refresh called');
  //     refreshApex(this.tempVariable);
  // }

  disconnectedCallback() {
    unsubscribe(this.channelName, (response) => {
      //console.log('Unsubscribed from channel ', response.channel);
    });
  }

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord(value) {
    console.log("--getRecord Wire Called", +this.recordId);
    this.record = value;

    console.log("getRecord Wire Called:", JSON.stringify(this.record));
    const { data, error } = value;
    if (data) {
      this.RecordTypeIdval = data.recordTypeId;
      console.log("getRecord data Called:", this.RecordTypeIdval);
    }
    if (error) {
      console.error("getRecord Error", error);
    }
  }

  // Wire adapter to fetch picklist values for STATUS_FIELD field
  @wire(getPicklistValues, {
    recordTypeId: "$RecordTypeIdval",
    fieldApiName: STATUS_FIELD
  })
  wiredPicklistValuesStatus(value) {
    this.picklistStatusFieldValues = value;
    console.log(
      "wiredPicklistValuesStatus--StatusField:",
      JSON.stringify(this.picklistStatusFieldValues)
    );
  }

  // Wire adapter to fetch picklist values for RESOLVED
  @wire(getPicklistValues, {
    recordTypeId: "$RecordTypeIdval",
    fieldApiName: RESOLVED
  })
  wiredPicklistValuesResolved({ data, error }) {
    if (data) {
      console.log(
        "wiredPicklistValuesResolved-Resolved:",
        JSON.stringify(data)
      );
      this.picklistResolvedValues = data.values.map((item) => ({
        label: item.label,
        value: item.value
      }));
      console.log(
        "wiredPicklistValuesResolved-Resolved--Picklist:",
        JSON.stringify(this.picklistResolvedValues)
      );
    } else if (error) {
      console.error("wiredPicklistValuesResolved-Resolved-Error", error);
    }
  }

  // Wire adapter to fetch picklist values for SUB_STATUS_FIELD
  @wire(getPicklistValues, {
    recordTypeId: "$RecordTypeIdval",
    fieldApiName: SUB_STATUS_FIELD
  })
  wiredPicklistValuesSubstatus(result) {
    this.wiredSubstatusResult = result; // Store the result
    this.tempVariable = result;
    console.log(
      "wiredPicklistValuesSubstatus-SUB_STATUS_FIELD:",
      JSON.stringify(this.picklistResolvedValues)
    );
    if (result.data) {
      this.tempVariable = result.data;
      this.handlepicklistdata(this.tempVariable);
    } else if (result.error) {
      console.error(
        "wiredPicklistValuesSubstatus-SUB_STATUS_FIELD-error:",
        JSON.stringify(result.error)
      );
    }
  }

  handlepicklistdata(substatusval) {
    console.log("--substatusval---" + JSON.stringify(substatusval));

    // this.record = JSON.stringify(this.record);
    if (this.record.data.fields.Status.value == "Resolved") {
      console.log("--Resolved---");
      this.picklistSubstatusValues = substatusval.values.filter((option) => {
        return option.validFor.includes(4);
      });
      console.log(
        "--Resolved -PickList ---" +
          JSON.stringify(this.picklistSubstatusValues)
      );
    } else if (
      this.record.data.fields.Status.value == "New" ||
      this.record.data.fields.Status.value == "Closed"
    ) {
      console.log("--New -Closed ---");
      this.picklistSubstatusValues = substatusval.values.filter((option) => {
        return option.validFor.includes(0);
      });

      console.log(
        "--New -Closed ---" + JSON.stringify(this.picklistSubstatusValues)
      );
    } else {
      console.log("--Last  ---");
      this.picklistSubstatusValues = substatusval.values.filter((option) => {
        return (
          option.validFor.includes(1) ||
          option.validFor.includes(2) ||
          option.validFor.includes(3)
        );
      });
      console.log("--Last  ---" + JSON.stringify(this.picklistSubstatusValues));
    }
    return null;
    console.log(
      "Test pIackslistsubstatus***" +
        JSON.stringify(this.picklistSubstatusValues)
    );
  }

  handleUpdateRecord(event) {
    this.showSpinner = true;
    //console.log('parent update called' + JSON.stringify(event.detail))
    const recordInput = event.detail;
    console.log(
      "---value from Child recordInput-- " + JSON.stringify(recordInput)
    );
    updateRecord(recordInput)
      .then((result) => {
        // this.picklistSubstatusValues = null
        // refreshApex(wiredRecord);
        // refreshApex(this.picklistStatusFieldValues)
        // refreshApex(this.picklistSubstatusValues)

        this.showSpinner = false;
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Status Updated!",
            variant: "success"
          })
        );
        //console.log('--this.record---' + JSON.stringify(this.record));
        console.log(
          "--parent picklistSubstatusValues--" +
            JSON.stringify(this.picklistSubstatusValues)
        );
        console.log("success!");
        this.RecordTypeIdval = this.record.recordTypeId;
        //this.RecordTypeIdval =  '012KH000000TRozYAG';
        console.log("---Record after success" + this.RecordTypeIdval);
        // refreshApex(wiredRecord);
      })
      .catch((error) => {
        this.showSpinner = false;

        console.log("failure => " + error.body.message);
        console.log("failure => " + JSON.stringify(error));
        this.handleError(error);
      });
  }

  handleError(error) {
    let fieldErrors = [];
    if (error.body && error.body.output && error.body.output.fieldErrors) {
      fieldErrors = Object.values(error.body.output.fieldErrors).flat();
      this.errorMessages = fieldErrors.map((err) => err.message);
    }
    if (error.body && error.body.output && error.body.output.errors) {
      fieldErrors = Object.values(error.body.output.errors).flat();
      this.errorMessages = fieldErrors.map((err) => err.message);
    }

    this.showToast(
      "Error",
      "Failed to update record: " + this.errorMessages.join(", "),
      "error"
    );
  }

  showToast(title, message, variant) {
    this.isLoading = false;
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
}