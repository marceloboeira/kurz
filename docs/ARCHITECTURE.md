# Architecture
> Specification, reasoning behind decisions of architecture, stack and dependencies.

## Index

* [What Is a URL Shortener?](#what-is-a-url-shortener)
* [Why You Should Create You Own?](#why-you-should-create-you-own)
* [Goals](#goals)
* [Challenges](#challenges)
  * [Short URL Generation](#short-url-generation)
  * [Capacity Planning](#capacity-planning)
  * [Performance](#performance)
* Alternatives
* Stack

# What Is a URL Shortener?

A URL Shortener is a service that creates short and easy links from big or complex URL, allowing people to use the alias to be redirected to the original. Such services are, usually, accompanied of statistics of access for each URL, API access and can serve as a unique place to have permanent aliases for common things on your company.

**What is the use**, you might wonder, here are some examples:

* **Compression**
  * e.g.: Twitter, given the limitations of the size of a tweet, the less characters one spends on URL the better.
  * > ... Twitter itself automatically shortens URLs with 30 characters or more - [Source][1]
  * You can also see similar minded tools on messaging platforms, facebook's `fb.me`...
* **Readability**
  * Ads have usually size/space/UX limitations, let's say SMS or even an image with a link.
  * e.g.: `shp.fy/computers` is better than `https://shopify.com/store/25/products/29192381`.
  * Lot's of companies use short links for referrals too, e.g.: `https://foo.bar/ref/marcelob`
* [**Permalinks**][6]
  * Links that likely won't change in the future, for consitency and usability perspectives.
  * e.g.: `spotify.com/faq` or even `spt.fi/faq`.
* **Statistics**
  * e.g: Information of how many people clicked on the link, which browsers they have, where they're from...
* **Standardization**
  * Short and useful internal links is common in companies with lots of employees. Google uses with `go/`, Airbnb `air/`
  * e.g.: `air/git`, `go/referrals`, `air/payslips`

**Paid alternatives**

* [bit.ly](https://bit.ly) - Paid service, you can use for free with limitations, paid users can also have their own domain, analytics...
* [tiny.cc](https://bit.ly) - Similar
* [cutt.ly](https://cutt.ly) - Similar

-------

# Why You Should Create You Own?

Mainly, the motivation is learning from the challenges that a URL Shortener can provide.

You can simplify the problem by lowering the requirements, I have [done it myself][9] a while back, it taught me different things at the time as the proprosed challenges were different.

As most system-related challenges, by adding scalability and performance as factors, the challenge becomes interesting.

Here are some of the challanges worth exploring:

e.g.:

* Reliability - `How often does the system fails? Under which conditions?`
* Performance - `How fast can we read/write data to it?`
* Data-Durability - `How long are URLs available for?`
* Storage-Capacity - `How many URLs can we store?`
* Scalability - `How/How much can I increase one of the above?`
* Consistency - `Operations can't violate consistency rules`

Among such challenges, I have spared a few and created a priority order. This is something common when designing such applications, given that the mentioned features of a system are usually inversely proportional, or two different sides of the same coin.

e.g.:
* a reliable database, that can never fail, might be really slow to ensure it will never fail.
* a long-term file system for backups might have severe capacity or performance limitations given it must copy data multiple times to ensure its durability.

## Goals

First let us look at the goals, then discuss in depth what are the exact features we'll be focusing on and the challenges they bring.

* Reliability - Low percentage of failures when reading/writing/redirecting. e.g.: what if the database goes down?
* Performance - Fast redirects/reads/writes. e.g.: how fast URL redirection takes?
* Consistency - Short URLs can't be overriden by new URLs. e.g.: hash collisions.
* UX - Simple to host, to use, and to scale.

On that order, we would give up UX or Consitency for Performance and Reliability, for instance. We'll dive into specifics later on.

### Non-Goals

* User Management - creating different users to own URLs
* Authentication - creating API specific keys and authentication
* Authorization - given different roles/permissions to users

## Challenges

### Short URL Generation

Given a resonably large URL, say:

```
https://my-long-link.com/a-very-long/path/with/numbers/90999.html
```

We would like to share it in a less verbose format, that being a tweet, a instant message...

When we think about it, it's mainly a hash-table. A key, value tuple that has the index with the short code being the key and the value being the long url, so that we can quickly lookup them.

* `http://krz.io/MEd21`
  * Lookup on a Hash Table
    * `MEd21: https://my-long-link.com/a-very-long/path/with/numbers/90999.html`

However, as [this blogpost][1] from Jeff Atwood states, creating a consistent hashing for this purpose is not a trivial task.

Let us take a look on how traditional hashing might not be the best idea.

### Traditional Hashing

We could use standard battle-tested hashing algorithms, let us say `MD5` for such purpose.

Here is the result of hashing the word `example` against the most-known hashing algorithms:

```
CRC32: 5cc22de8
MD5: 1a79a4d60de6718e8e5b326e338ae533
MD4: e1821c366558728f70e054fbf9db7b64
MD2: fd7a532a863c3394b89b38d18cf12073
SHA1: c3499c2729730a7f807efb8676a92dcb6f8a3f8f
SHA224: 312b3e578a63c0a34ed3f359263f01259e5cda07df73771d26928be5
SHA256: 50d858e0985ecc7f60418aaf0cc5ab587f42c2570a884095a9e8ccacd0f6545c
SHA384: feeebf884f6dabe6eca8d68e373d6be488cdaa5eb764e895290336ffe9ff969686f2a9d362e9a8bbddf6e7b2e1455f2d
SHA512: 3bb12eda3c298db5de25597f54d924f2e17e78a26ad8953ed8218ee682f0bbbe9021e2f3009d152c911bf1f25ec683a902714166767afbd8e5bd0fb0124ecb8a
```
> You can do that yourself [here][10]

##### Idempotency

One of the good parts is that such alternative is **idempotent**. Meaning that, if the content (e.g.: an URL) doesn't change, the hash won't change eithere. Hashing the word `example` with this algorithm in any computer would, or should, generate the same result.

Idempotency is good on that sense, because if multiple users try to shorten the same URL, we would **save space and lookup time** by avoiding saving the same hash over and over. We'll discuss those in depth later on.

##### Collision Probabilities

Besides that, such algorithms have [known collision probabilities][11], which guide us on figuring out the capacity and durability of the URLs. e.g.: generating 10M URLs per month, in 2 years the chance of collision will be X.

If you like hashing read more about MD5 collisions [here][12] and [here][11].

##### Length

There is a deal breaker constraint with traditional hashing, which is exactly the reason why collision probabilities are so low, it's the obvious huge length of those hashes.

* SHA512 always return a `512` chars long string.
* MD5  always return a `128` chars long  string.

It defeats the whole purpose, e.g.: `https://krz.io/1a79a4d60de6718e8e5b326e338ae533`

##### The Birthday Paradox

Even using a not so lengthy algorithm, as `CRC32` the string would have around 8 chars which increases the change of collision a lot.

A naive attempt to calculate the collision would be to look at the amount of possibilities by the amount of permutations, that being:

8 random characters from `a-z` and `0-9` give us around 36 different chars, so:

```
n! / (n - r)!
```

where n is the amount of possibilities and n is the amount of samples.

```
n = 36
r = 8

36! / (36 - 8)! = 1.220096908𝐸+12
```
> [Source][14]

That is, `1 trillion 220 billion 96 million 908 thousand 800`, or if we were have 1000 URLs being created every second, we could go on for almost **40 years** before running out of options.

However, the above is not the **collision probability**, 1 in 1 trillion, given to the [birthday paradox][13] that probability is much lower, since the space of possibilities for URLs is so much broader than 1 trillion.

Even that we could generate more than 1 trillion different hashes, it doesn't ensure we won't hit a collision right from start.

#### Conclusion

Traditional Hashing is not a good alternative, quoting [Jeff's article][1] once more:

> URL shortening services can't rely on traditional hashing techniques

#### What are the alternatives then?

Jeff's article comes to a good conclusion, to create a produciton-grade URL shortener, the short slug can't be the hash of the URL, yet a brute forced sequence of characters that grows in size over time.

He says:
> Each new URL gets a unique three character combination until no more are left


### HashIDs

HashID with
`36^8` = `2 trillion 821 billion 109 million 907 thousand 456`

https://hashids.org
https://github.com/nikolay-govorov/nanoid

Best Option:
- Grows on demand (e.g.: 1 -> a, 1000000 -> aF*_)
- Consistent (not random)
- Based on a number
- Offers Salt which provides a nice way to generate unique IDs

My main concern:
1. How to maintain a atomic (across nodes) auto-incremented -> PGSQL Sequences
2.  How to concilliate Custom URLs with autogenerated by number

  - if you have an incremental integer ID that you convert to String and you decide to override that string, that number will generate a string that won't be able to generate anymore, so you'll loose such an index.
  - if you auto generate, you reserve an index
  - if you reserve a "ID"
  - not possible to claim IDs back?

https://hashids.org/rust/
https://github.com/archer884/harsh

PostgreSQL


| Name        | Storage Size | Range                         |
|-------------|--------------|-------------------------------|
| SMALLSERIAL | 2 bytes      | 1 to 32,767                   |
| SERIAL      | 4 bytes      | 1 to 2,147,483,647            |
| BIGSERIAL   | 8 bytes      | 1 to 922,337,2036,854,775,807 |

8 * 10M rows = 80MB of ids. which is pretty reasonable.

## Capacity Planning

Maximum URL size seems not to be a common agreement over the web, yet, the number that popped up the most was 2048 bytes.

> The HTTP protocol does not place any a priori limit on the length of a URI. Servers MUST be able to handle the URI of any resource they serve, and SHOULD be able to handle URIs of unbounded length if they provide GET-based forms that could generate such URIs. A server SHOULD return 414 (Request-URI Too Long) status if a URI is longer than the server can handle (see section 10.4.15).
Source: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html

Long URL: 2048
Short URL: from 1 up to 20 (Let's take 15 as a good compromise)


https://mb7.c/a7lLaKc72Has


https://instagram-engineering.com/sharding-ids-at-instagram-1cf5a71e5a5c
https://www.educative.io/collection/page/5668639101419520/5649050225344512/5668600916475904

# Alternatives

* https://github.com/YOURLS/YOURLS
* https://github.com/thedevs-network/kutt
* https://github.com/cydrobolt/polr

# Stack

## Backend: Rust

Rust is an extremelly safe statically typed compiled language. The compiler, prevents lot sof ....

Listed here some modern alternatives for rust, and the reason(s) why they're rulled out of this project.

### Haskell

Nothing to levarage from functional programing on the backend, mainly IO manipulation.

### Go

big runtime, GC concerns and such

#### Scala

jvm-based, big memory footprint, high-latency and resource demanding

### C

huge operational overhead

## Frontend: Elm

Elm is a functional.

---------
[1]: https://blog.codinghorror.com/url-shortening-hashes-in-practice/
[2]: https://www.youtube.com/watch?v=JQDHz72OA3c
[3]: https://michiel.buddingh.eu/distribution-of-hash-values
[4]: https://www.educative.io/collection/page/5668639101419520/5649050225344512/5668600916475904
[5]: https://engineering.checkr.com/introducing-flagr-a-robust-high-performance-service-for-feature-flagging-and-a-b-testing-f037c219b7d5
[6]: https://en.wikipedia.org/wiki/Permalink
[7]: https://github.com/kellegous/go
[9]: https://github.com/marceloboeira/shortify
[10]: http://www.toolsvoid.com/multi-hash-generator
[11]: https://stackoverflow.com/a/288519
[12]: https://crypto.stackexchange.com/a/12679
[13]: https://www.youtube.com/watch?v=KtT_cgMzHx8
[14]: https://www.calculatorsoup.com/calculators/discretemathematics/permutations.php
