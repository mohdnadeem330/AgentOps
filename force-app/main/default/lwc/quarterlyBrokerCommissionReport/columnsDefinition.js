export const EXAMPLES_COLUMNS_DEFINITION_BASIC = [

    {
        type: 'text',
        fieldName: 'column0',
        label: '',
        // initialWidth: 200,
        initialWidth: 10,
        cellAttributes: { class: 'column-id' }
    },
    {
        type: 'text',
        fieldName: 'column5',
        label: 'Quarter',
        initialWidth: 100,
        cellAttributes: { class: 'rooms-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column15',
        label: 'Year',
        initialWidth: 80,
        cellAttributes: { class: 'rooms-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column1',
        label: 'Agency Name',
        initialWidth: 150,
        // initialWidth: 200,
        cellAttributes: { class: 'agency-name-cell' /*important for reponsive */ }
    },
    /*{
        type: 'text',
        fieldName: 'column2',
        label: 'Agent Name',
        // initialWidth: 200,
        cellAttributes: { class: 'agent-name-cell' }
    },*/
    {
        type: 'text',
        fieldName: 'column3',
        initialWidth: 150,
        label: 'Property',
        cellAttributes: { class: 'property-cell' /*important for reponsive */ }
    },
    {
        type: 'text',
        fieldName: 'column4',
        initialWidth: 150,
        label: 'Unit Number',
        cellAttributes: { class: 'unit-number-cell' /*important for reponsive */ }
    },
    //Moved above as customer Name
    {
        type: 'number',
        fieldName: 'column6',
        initialWidth: 120,
        label: 'Net Price',
        cellAttributes: { class: 'net-price-cell' /*important for reponsive */ }
    },
    {
        type: 'date',
        fieldName: 'column7',
        initialWidth: 100,
        label: 'Order Date',
        cellAttributes: { class: 'order-date-cell' /*important for reponsive */ }
    },
    {
        type: 'number',
        fieldName: 'column8',
        initialWidth: 120,
        label: 'Commission',
        cellAttributes: { class: 'commission-cell' /*important for reponsive */ }
    },
    {
        type: 'percent',
        typeAttributes: {
            minimumFractionDigits: '2',
            maximumFractionDigits: '5',
        },
        fieldName: 'column9',
        initialWidth: 120,
        label: 'Rate',
        cellAttributes: { class: 'rate-cell' /*important for reponsive */ }
    },
    /*{
        label: 'Sales Order Status',
        fieldName: 'column14',
        type: 'text',
        cellAttributes: { class: 'sales-order-status'}
    },*/
    {
        label: 'Status',
        initialWidth: 150,
        fieldName: 'column10',
        type: 'percent',
        cellAttributes: {
            iconName: { fieldName: 'statusIcon' },
            iconPosition: 'left',
        }

    },
    {

        label: 'Action',
        fieldName: 'column12',
        type: 'button',
        initialWidth: 60,
        typeAttributes: {
            iconName: 'utility:edit',

            name: 'View',
            title: 'editTitle',
            disabled: false,
            value: 'test'

        },
        cellAttributes: {
            class: 'custom-grid-icon file-icon ',
            alignment: `left`
        }
    },
    {

        label: '',
        fieldName: 'column13',
        initialWidth: 60,
        type: 'button',
        typeAttributes: {
            iconName: 'utility:edit',

            name: 'Expand',
            title: 'editTitle',
            disabled: false,
            value: 'test'

        },
        cellAttributes: {
            class: 'custom-grid-icon collapse-icons',
            alignment: `left`
        }
    }
];


export const EXAMPLES_DATA_BASIC = [
    {
        column0: 1,
        column1: "agencyName",
        column2: "Rola Zayat",
        column3: "Al Ghadeer - R1",
        column4: "Al Ghadeer - R1",
        column5: "1 BHK",
        column6: "44.55k",
        column7: "11-12-21",
        column8: "44.55k",
        column9: "2.5",
        column10: "",
        statusIcon: 'utility:ban',
        column11: "External",
        column12: "",
        column13: "",
        _children: [
            {
                column0: 1.1,
                column1: 'Paid Amount:',
                column2: '',
                column3: "Invoice #:",
                column4: "2",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",

                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",
            },
            {
                column0: 1.2,
                column1: 'Invoice Date:  Invoice Date:',
                column2: '',
                column3: "Payment Due Date:",
                column4: "22/01/2022",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",

                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",

            }
        ]
    },
    {
        column0: 2,
        column1: "agencyName",
        column2: "Rola Zayat",
        column3: "Al Ghadeer - R1",
        column4: "Al Ghadeer - R1",
        column5: "1 BHK",
        column6: "44.55k",
        column7: "11-12-21",
        column8: "44.55k",
        column9: "2.5",
        column10: "",
        statusIcon: 'utility:ban',
        column11: "External",
        column12: "",
        column13: "",
        _children: [
            {
                column0: 2.1,
                column1: 'Paid Amount:',
                column2: '',
                column3: "Invoice #:",
                column4: "2",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",

                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",
            },
            {
                column0: 2.2,
                column1: 'Invoice Date:  Invoice Date:',
                column2: '',
                column3: "Payment Due Date:",
                column4: "22/01/2022",
                column5: '',
                column6: '',
                column7: 'Paid Flag: -',
                column8: "44.55k",
                column9: "2.5",
                column10: "",

                column11: "Cleared Date: Cleared Date:",
                column12: "",
                column13: "",

            }
        ]
    }


];