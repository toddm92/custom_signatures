# Custom Signatures

This is a repo of custom signature samples that you can use in your environment. Source code files are provided for demonstration purposes only.

Please email support@evident.io if you have any questions.

# Custom Signature Tutorial ( javascript )

A custom signature will have two sections, `config` and `perform`.

##`config`

An example `config` section:
```javascript
dsl.configure(function(c) {
  c.valid_regions = ['us_east_1'];
  c.identifier = 'AWS:EC2-909'
  c.deep_inspection = ['volume_type', 'volume_id'];
  c.unique_identifier = ['volume_id'];
});
```
`dsl.configure` is a function passed a callback that receives an object `c` as
 the first argument.  Inside the anonymous function you will change the
  configuration metadata for the signature.


####configuration metadata

`valid_regions` An array of valid regions is passed, ex. `us_east_1` `us_west_2`

`identifier` A unique string identifying the signature in the database. Usually
takes the form `AWS:SERVICE_CODE-SOME_NUMBER`,  ex. `AWS:EC2-303`
`AWS:R52:909`

`deep_inspection` An array of fields that provide additional information beyond
the status when an alert is viewed in the actual report.  These fields are
populated in the `perform` block.

`deep_inspection` An array of fields that are used to list the alert as unique
 in the database.

##`perform`

The `perform` section is a function that is passed the
 [AWS SDK](http://docs.aws.amazon.com/sdkforruby/api/) as an object.  You use
this `aws` object to make calls to AWS.  

Perform block psuedocode looks like
```javascript
function perform(aws){
  try {

    // make a container for returned alerts
    var alerts = []

    // make some AWS calls to get an array of resources
    // for each resource
    //    read some resource information
    //    save some of that resource information to the report
    //    compare it to a desired value or state
    //    push a dsl.fail() or dsl.pass() to the alerts container
    //      ex. alerts.push(dsl.fail({message:'failed'}))

    return alerts;

  } catch(err){
    return dsl.error({
      errors: err.message
    })
  }
}
```



An example `perform` section:
```javascript

function perform(aws) {
  try {

    // make the container for returned alerts
    var alerts = [];

    var region = aws.region;

    // these are AWS SDK calls to get a list of resources to check
    var volumes = aws.ec2.describe_volumes().volumes;

    // this is our condition we are searching for in this signature
    // we want to enforce a specific volume type in this region
    // if you change the variable below to 'gp2' it will use that
    var type_to_check_for = 'standard'


    // for each volume returned from the AWS SDK call
    volumes.map(function(volume) {

      // this is where you specify the data for the fields listed in the
      // deep_inspection array
      // create an object and give it some information
      var report = {
        volume_type: volume.volume_type,
        volume_id: volume.volume_id
      };

      // call dsl.set_data() with that object as the argument and the alert
      // will now have this additional information associated with it
      dsl.set_data(report);

      // our condition check
      // is the volume.volume_type not the same as our desired type?
      if (volume.volume_type !== type_to_check_for) {

        // in this block the volume.volume_type !== type_to_check_for
        // You will create a failed alert with a message.
        // The message is a string, and the failed alert is created by calling
        // dsl.fail({ message: 'some message indicating why'})
        // You then push that object on to the alerts array and the next
        // volume is checked

        var fail_message = 'volume with id '
        fail_message += volume.volume_id + ' is of type '
        fail_message += volume.volume_type + ' and not of type '
        fail_message += type_to_check_for;

        // add the alert to the array of alerts
        alerts.push(dsl.fail({
          message: fail_message
        }));

      } else {

        // in this block the volume.volume_type === type_to_check_for
        // You will create a pass alert with a message.

        var pass_message = 'volume with id ' + volume.volume_id
        pass_message += ' is of type ' + volume.volume_type;

        // add the alert to the array of alerts
        alerts.push(dsl.pass({
          message: pass_message
        }));

      }

    })

    // return the array of alerts
    return alerts;

  } catch (err) {
    return dsl.error({
      errors: err.message
    });
  }
}
```
