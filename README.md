![logo](https://cloud.githubusercontent.com/assets/3109377/22114566/e5a2fc2a-de61-11e6-8974-824b71badce9.png)

# Kafka Shock

A proof of concept to play with Apache Kafka from a different perspective. 

## Introduction

Sometimes, the best way to learn a system is by injecting failures on it and observe how the system behaves under those conditions. I think that it would be nice to have a tool to play around with Kafka at the protocol level. A tool that  allows to inspect, alter and block the Kafka protocol primitives. By doing so, it is possible to inject failures at the proper level of granularity (e.g. block all the *produce_request* types from a given *client-id* and routed to an specific topic)

## Code

The current code is a quick and dirty script to illustrate the sniffer approach. It allows to inspect the traffic, set a condition for an specificy request type and some details of it (e.g. topic, client-id, etc) and by using *pry* to set a breakpoint interactively translate the captured packet to IPTables rules. 

The main point is to translate Kafka Protocol request types into IPTables rules and by leveraging IPTables packet matching capabilities we can block specific request types with an specific payload (e.g. client-id, topic, message content, etc)

I think it is possible as well to inject byzantine failures by injecting request types with misleading information. Kafka doesn't support this kind of failures but it could be fun for educational purposes.

I have considered to use a proxy approach to make traffic manipulation easier. I have an implementation of that approach using [Ronin](https://ronin-ruby.github.io/) but for the PoC it was easier to setup a sniffer than a proxy with the downside that you need to rely on IPTables to block the traffic. 


## Resources

This code was used in the demo of the presentation [**Kafka Shock: Dissecting Kafka protocol for fun and profit**](https://drive.google.com/file/d/0Bx1znQqwIgviN0VFS1FwQXo0OEU/view) at the [**Apache Kafka London Meetup group**](https://www.meetup.com/Apache-Kafka-London) 