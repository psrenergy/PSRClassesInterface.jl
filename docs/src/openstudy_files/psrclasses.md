# psrclasses.json and Defaults

The `psrclasses.json` file stores the data from the `OpenStudy` model.

It has the following structure:

```json
{
    "CustomCollection": {
        "AVId": "string",
        "name": "name",
        "code": 0,
        "Values": [
            0.0
        ],
        "Cost": 1.5
    },
    "SecondCollection": {
        "AVId": "string2",
        "name": "name2",
        "Type": 3,
        "Generation(1)": [
            0.0,2.0
        ],
        "Generation(2)": [
            5.0,3.0
        ],
        "code":1
    }
}

```

!!! note
    In the `SecondCollection` there are two parameters `Generation(1)` and `Generation(2)`. They represent the values for the parameter `Generation` in two different dimensions.


## Defaults

The `defaults.json` file stores the default values for the parameters in the PSRI study. It has the same structure as the `psrclasses.json`.
It is not a mandatory file, but it can be useful for the case when there are missing parameters for an element being created.