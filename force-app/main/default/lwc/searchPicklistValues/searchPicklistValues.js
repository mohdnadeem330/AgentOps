import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';

export default class SearchPicklistValues extends LightningElement {
    @api fieldlabel;
    @api objectname;
    @api displayname;
    @api picklistplaceholder;
    @api ispicklistdisabled;
    @api customStyle = 'background-color: white;';
    @api objectrecordtypeid;

    isListening = false;
    @track pickListOrdered = [];
    @track searchResults = [];
    selectedSearchResult;

    selectedValueholder;

    @api
    get selectedvalue() {
        return this.selectedValueholder;
    }
    set selectedvalue(value) {
        this.selectedValueholder = value;
        if (this.pickListOrdered.length > 0) {
            this.selectedSearchResult = this.pickListOrdered.find(
                (pickListOption) => pickListOption.value === value
            );
        }
    }

    get selectedValueLabel() {
        return this.selectedSearchResult?.label ?? null;
    }

    @wire(getPicklistValuesByRecordType, { objectApiName: '$objectname', recordTypeId: '$objectrecordtypeid' })
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.processPicklistValues(data);
        } else if (error) {
            console.error('Error fetching picklist values:', error);
        }
    }

    connectedCallback() {
        if (this.fieldlabel && this.objectname && this.recordtypeid) {
            this.fetchData();
        }
    }

    renderedCallback() {
        if (!this.isListening) {
            window.addEventListener('click', this.handleOutsideClick);
            this.isListening = true;
        }
    }

    fetchData() {
        // fetchData logic is now handled by wired services
    }

    processPicklistValues(data) {
        const picklistValues = data.picklistFieldValues[this.fieldlabel]?.values || [];
        const uniqueItems = new Map();
        picklistValues.forEach(item => {
            if (item.label && !uniqueItems.has(item.label)) {
                uniqueItems.set(item.label, item);
            }
        });
        this.pickListOrdered = Array.from(uniqueItems.values())
            .sort((a, b) => a.label.localeCompare(b.label));
        if (this.selectedValueholder) {
            this.selectedSearchResult = this.pickListOrdered.find(
                (pickListOption) => pickListOption.value === this.selectedValueholder
            );
        }
    }

    handleOutsideClick = (event) => {
        const isInsideComponent = this.template.host.contains(event.target);
        if (!isInsideComponent) {
            this.clearSearchResults();
        }
    }

    search(event) {
        const input = event.detail.value.toLowerCase();
        if (!input) {
            this.clearSearchResults();
        } else {
            this.searchResults = this.pickListOrdered.filter((pickListOption) =>
                pickListOption.label.toLowerCase().includes(input)
            );
        }
    }

    selectSearchResult(event) {
        const selectedvalue = event.currentTarget.dataset.value;
        this.selectedSearchResult = this.pickListOrdered.find(
            (pickListOption) => pickListOption.value === selectedvalue
        );
        this.selectedValueholder = selectedvalue;
        this.dispatchEvent(new CustomEvent('picklistselect', {
            detail: { value: selectedvalue, label: this.selectedSearchResult.label }
        }));
        this.clearSearchResults();
    }

    clearSearchResults() {
        this.searchResults = [];
    }
}