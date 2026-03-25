# 5gc-mysql

The `5gc-mysql` pod provides the MySQL database used by the 5G Core Network Functions to store subscription data, session data, and other operational information.

This section lists useful commands for debugging, inspection, and operational verification.


### View Logs

```bash
kubectl logs -n nexslice deploy/5gc-mysql
````

### Open a Shell Inside the Pod

```bash
kubectl exec -it -n nexslice deploy/5gc-mysql -- bash
```

### Connect to MySQL

```bash
mysql -h 127.0.0.1 -u root -p
```

Default password (lab deployment):

```text
linux
```
### List Databases

```sql
SHOW DATABASES;
```

### Inspect OAI Database

```sql
USE oai_db;
SHOW TABLES;
```

### Verify UE Subscription Data

```sql
SELECT * FROM SessionManagementSubscriptionData LIMIT 5;
```

This confirms that UDR / UDM successfully provisioned UE profiles.



# oai-amf

The `oai-amf` pod runs the Access and Mobility Management Function (AMF), responsible for UE registration, mobility management, NAS signaling, and NGAP communication with the gNB.

This section provides useful operational and debugging commands.

---

### View Logs

```bash
kubectl logs -n nexslice deploy/oai-amf
````

Follow logs in real time (VERY useful during UE attach):

```bash
kubectl logs -f -n nexslice deploy/oai-amf
```

### Debug UE Registration

Watch logs while UE starts:

```bash
kubectl logs -f -n nexslice deploy/oai-amf | grep -iE "Registration|NGAP|NAS"
```

### Open a Shell Inside the Pod

```bash
kubectl exec -it -n nexslice deploy/oai-amf -- bash
```

### Verify AMF Process is Running

From inside the pod:

```bash
ps aux | grep amf
```


# oai-smf

The `oai-smf` pod runs the Session Management Function (SMF), responsible for PDU session establishment, IP address allocation coordination with the UPF, and session lifecycle management for connected UEs.

This section provides useful operational and debugging commands.

---

### View Logs

```bash
kubectl logs -n nexslice deploy/oai-smf
````

Follow logs in real time:

```bash
kubectl logs -f -n nexslice deploy/oai-smf
```

### Debug PDU Session Establishment

Follow logs during UE PDU session setup:

```bash
kubectl logs -f -n nexslice deploy/oai-smf | grep -iE "PDU|session|N4|PFCP"
```

### Check PFCP Interaction with UPF

```bash
kubectl logs -n nexslice deploy/oai-smf | grep -i pfcp
```

### Check NRF Registration

```bash
kubectl logs -n nexslice deploy/oai-smf | grep -i nrf
```

You should see the SMF registering itself and discovering peer Network Functions through the NRF.


### Check PDU Session Errors

```bash
kubectl logs -n nexslice deploy/oai-smf | grep -iE "error|fail|reject|timeout"
```

This is useful when UE registration succeeds but data session establishment fails.

---

### Cross-check with AMF Logs

During a UE data session attempt, compare with:

```bash
kubectl logs -f -n nexslice deploy/oai-amf | grep -iE "PDU|SMF|N1N2"
```

This helps confirm whether the request reached the SMF and whether the AMF-SMF signaling path is working.


### Open a Shell Inside the Pod

```bash
kubectl exec -it -n nexslice deploy/oai-smf -- bash
```

### Verify SMF Process is Running

From inside the pod:

```bash
ps aux | grep smf
```



# oai-upf

The `oai-upf` pod runs the User Plane Function (UPF), responsible for packet forwarding, GTP-U tunnel handling, and data plane connectivity between the UE and external data networks.

This section provides useful operational and debugging commands.

### View Logs

```bash
kubectl logs -n nexslice deploy/oai-upf
````

Follow logs in real time:

```bash
kubectl logs -f -n nexslice deploy/oai-upf
```

### Debug PFCP Session Creation

```bash
kubectl logs -n nexslice deploy/oai-upf | grep -i pfcp
```
### Open a Shell Inside the Pod

```bash
kubectl exec -it -n nexslice deploy/oai-upf -- bash
```

### Verify UPF Process is Running

From inside the pod:

```bash
ps aux | grep upf
```





## oai-nrf

The `oai-nrf` pod runs the Network Repository Function (NRF), responsible for Network Function registration, discovery, and service authorization across the 5G Core.

All control plane Network Functions (AMF, SMF, UDM, AUSF, etc.) must successfully register with the NRF before any UE procedures can work.

This section provides useful operational and debugging commands.


### View Logs

```bash
kubectl logs -n nexslice deploy/oai-nrf
````

Follow logs in real time:

```bash
kubectl logs -f -n nexslice deploy/oai-nrf
```


### Verify AMF Registration

```bash
kubectl logs -n nexslice deploy/oai-nrf | grep -i amf
```


### Verify SMF Registration

```bash
kubectl logs -n nexslice deploy/oai-nrf | grep -i smf
```

### Check for Registration Errors

```bash
kubectl logs -n nexslice deploy/oai-nrf | grep -iE "error|fail|reject"
```

