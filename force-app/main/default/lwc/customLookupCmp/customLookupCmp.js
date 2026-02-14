import { api, wire, LightningElement, track } from "lwc";
import { FlowAttributeChangeEvent } from "lightning/flowSupport";

import getLookupValues from "@salesforce/apex/ECSS_CustomAdvanceLookupCmpController.getLookupValues";
import getinitRecord from "@salesforce/apex/ECSS_CustomAdvanceLookupCmpController.getinitRecord";
import gerRecentlyCreatedRecords from "@salesforce/apex/ECSS_CustomAdvanceLookupCmpController.gerRecentlyCreatedRecords";

export default class CustomLookupCmp extends LightningElement {
  //public properties
  @api accountCreationCheckbox = false;
  @api uniqueName = "Account";
  @api initialLookupValue = "";
  @api objectAPIName = "Account";
  displayLabelField = "Name";
  @api iconName = "standard:account";
  @api labelForComponent = "Account";
  @api placeHolder = "Search Account";
  @api recordLimit = 5;
  @api labelHidden = false;
  @api selectedUnit = "";
  searchKeyWord = "";
  @api selectedRecordString = "";
  @api selectedRecord; // Use for storing the SELECTED sObject Record
  @api where = "";
  @api defaultLookupRecord;
  @track showDropdown = false;
  // private properties
  @track selectedRecordLabel = "";
  searchRecordList = []; // Use for storing the list of search records returned from apex class
  message = "";
  spinnerShow = false;
  error = "";
  noRecordFound = false;

  renderedCallback() {
    if (this.selectedRecord) {
      this.selectedRecordString = JSON.stringify(this.selectedRecord);
      this.selectedRecordLabel = this.selectedRecord.Name; //data[this.displayLabelField];
      let container = this.template.querySelector(".custom-lookup-container");
      container.classList.remove("slds-is-open");

      // this.selectedRecord = this.searchRecordList.find(data => data.Id === this.selectedRecord.Id);
      this.selectedRecordLabel = this.selectedRecord.Name; //this.selectedRecord[this.displayLabelField];
      this.selectedRecordString = JSON.stringify(this.selectedRecord);
      console.log("SelectedRecords" + JSON.stringify(this.selectedRecord));
      console.log(this.selectedRecordLabel);

      this.fireLookupUpdateEvent(this.selectedRecord);
      this.selectionRecordHelper();
      console.log("Before Dispatch : ");
      this.dispatchEvent(
        new FlowAttributeChangeEvent("selectedRecord", this.selectedRecord)
      );
      this.dispatchEvent(
        new FlowAttributeChangeEvent(
          "selectedRecordString",
          this.selectedRecordString
        )
      );
      console.log("After Dispatch : ");
    }
  }

  connectedCallback() {
    /* if (this.initialLookupValue != '') {
            getinitRecord({ recordId: this.initialLookupValue, objectAPIName: this.objectAPIName, fieldNames: this.displayLabelField })
                .then((data) => {
                    if (data != null) {
                        console.log('getinitRecord —> ', JSON.stringify(data));
                        this.selectedRecord = data;
                        this.selectedRecordString = JSON.stringify(data);
                        this.selectedRecordLabel = data.Name; //data[this.displayLabelField];
                        console.log('selectedRecordLabel : ', this.selectedRecordLabel);
                        this.selectionRecordHelper();
                    }
                })
                .catch((error) => {
                    console.log('getinitRecord Error —> ' + JSON.stringify(error));
                    this.error = error;
                    this.selectedRecord = {};
                });
        }*/
  }

  handleClickOnInputBox(event) {
    let container = this.template.querySelector(".custom-lookup-container");
    container.classList.add("slds-is-open");
    this.spinnerShow = true;
    console.log(this.where);

    if (
      typeof this.searchKeyWord === "string" &&
      this.searchKeyWord.trim().length === 0
    ) {
      /*   gerRecentlyCreatedRecords({ objectAPIName: this.objectAPIName, fieldNames: this.displayLabelField, whereCondition: this.where, customLimit: this.recordLimit })
                .then((data) => {
                    if (data != null) {
                        try {
                            console.log('gerRecentlyCreatedRecords —> ', JSON.stringify(data));
                            this.spinnerShow = false;
                            console.log('Before Pares : ', JSON.stringify(data));
                            this.searchRecordList = JSON.parse(JSON.stringify(data));
                            console.log('After Pares : ', JSON.stringify(data));
                            this.hasRecord();
                        } catch (error) {
                            console.log('error: ' + error.message);
                            this.hasRecord();
                        }
                    }
                })
                .catch((error) => {
                    console.log('gerRecentlyCreatedRecords Error —> ' + JSON.stringify(error));
                    this.error = error;
                });*/
    } else if (
      typeof this.searchKeyWord === "string" &&
      this.searchKeyWord.trim().length > 0
    ) {
      getLookupValues({
        searchKeyWord: this.searchKeyWord,
        objectAPIName: this.objectAPIName,
        whereCondition: this.where,
        fieldNames: this.displayLabelField,
        customLimit: this.recordLimit,
        SelectedUnit: this.selectedUnit
      })
        .then((data) => {
          if (data != null) {
            console.log("getLookupValues —> ", JSON.stringify(data));
            this.spinnerShow = false;
            this.searchRecordList = JSON.parse(JSON.stringify(data));
            this.error = undefined;
            this.hasRecord();
          }
        })
        .catch((error) => {
          console.log("getLookupValues Error —> " + JSON.stringify(error));
          this.error = error;
          this.selectedRecord = {};
        });
    }
  }

  fireLookupUpdateEvent(value) {
    const oEvent = new CustomEvent("customLookupUpdateEvent", {
      detail: {
        name: this.uniqueName,
        selectedRecord: value
      }
    });
    this.dispatchEvent(oEvent);
  }

  handleKeyChange(event) {
    this.searchKeyWord = event.detail.value;
    console.log(this.searchKeyWord);
    if (
      typeof this.searchKeyWord === "string" &&
      this.searchKeyWord.trim().length > 0
    ) {
      this.searchRecordList = [];
    }
  }

  // handleOnblur(event) {
  //     if (!this.template.querySelector('.slds-combobox').contains(event.relatedTarget)) {

  //         let container = this.template.querySelector('.custom-lookup-container');
  //         container.classList.remove('slds-is-open');
  //         this.spinnerShow = false;
  //         this.searchRecordList = [];
  //     }
  // }
  handleFocus() {
    this.showDropdown = true; // Show dropdown when the input is focused
  }

  handleBlur(event) {
    // Add a small delay to allow the selection to complete
    setTimeout(() => {
      // Check if the related target (where the focus is moving) is inside the dropdown
      if (
        !this.template
          .querySelector(".slds-combobox")
          .contains(event.relatedTarget)
      ) {
        // Close the dropdown only if focus is outside the input and dropdown
        this.showDropdown = false;
        let container = this.template.querySelector(".custom-lookup-container");
        container.classList.remove("slds-is-open");
      }
    }, 200);
  }
  handleSelectionRecord(event) {
    var recid = event.target.getAttribute("data-recid");
    console.log("recid : ", recid);

    let container = this.template.querySelector(".custom-lookup-container");
    container.classList.remove("slds-is-open");

    this.selectedRecord = this.searchRecordList.find(
      (data) => data.Id === recid
    );
    this.selectedRecordLabel = this.selectedRecord.Name; //this.selectedRecord[this.displayLabelField];
    this.selectedRecordString = JSON.stringify(this.selectedRecord);
    console.log("SelectedRecords" + JSON.stringify(this.selectedRecord));
    console.log(this.selectedRecordLabel);

    this.fireLookupUpdateEvent(this.selectedRecord);
    this.selectionRecordHelper();
    console.log("Before Dispatch : ");
    this.dispatchEvent(
      new FlowAttributeChangeEvent("selectedRecord", this.selectedRecord)
    );
    this.dispatchEvent(
      new FlowAttributeChangeEvent(
        "selectedRecordString",
        this.selectedRecordString
      )
    );
    event = new CustomEvent("dataevent", {
      detail: this.selectedRecord
    });
    this.dispatchEvent(event);

    console.log("After Dispatch : ");
  }

  selectionRecordHelper() {
    let custom_lookup_pill_container = this.template.querySelector(
      ".custom-lookup-pill"
    );
    custom_lookup_pill_container.classList.remove("slds-hide");
    custom_lookup_pill_container.classList.add("slds-show");

    let search_input_container_container = this.template.querySelector(
      ".search-input-container"
    );
    search_input_container_container.classList.remove("slds-show");
    search_input_container_container.classList.add("slds-hide");
  }

  clearSelection() {
    let custom_lookup_pill_container = this.template.querySelector(
      ".custom-lookup-pill"
    );
    custom_lookup_pill_container.classList.remove("slds-show");
    custom_lookup_pill_container.classList.add("slds-hide");

    let search_input_container_container = this.template.querySelector(
      ".search-input-container"
    );
    search_input_container_container.classList.remove("slds-hide");
    search_input_container_container.classList.add("slds-show");

    // Clear relevant fields and lists
    this.selectedRecord = null;
    this.selectedRecordLabel = "";
    this.selectedRecordString = "";
    this.searchKeyWord = "";
    this.searchRecordList = [];
    this.noRecordFound = false; // Resetting no record flag

    // Dispatch events to clear selections
    this.fireLookupUpdateEvent(this.selectedRecord);
    // this.dispatchEvent(new CustomEvent('dataevent', { detail: this.selectedRecord }));

    console.log("Selection cleared");
  }

  clearSelectionHelper() {
    this.selectedRecord = {};
    this.selectedRecordLabel = "";
    this.selectedRecordString = this.searchKeyWord = "";
    this.searchRecordList = [];
    this.dispatchEvent(new FlowAttributeChangeEvent("selectedRecord", null));
    this.dispatchEvent(
      new FlowAttributeChangeEvent("selectedRecordString", "")
    );
  }

  hasRecord() {
    if (this.searchRecordList && this.searchRecordList.length > 0) {
      this.noRecordFound = false;
      console.log("this.noRecordFound : ", this.noRecordFound);
    } else {
      this.noRecordFound = true;
      console.log("this.noRecordFound : ", this.noRecordFound);
    }
  }
}